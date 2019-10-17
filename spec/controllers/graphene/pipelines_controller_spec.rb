# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::PipelinesController, :with_auth_token, type: :controller do
  routes { Graphene::Engine.routes }

  let(:time) { Time.now }

  let(:data) do
    { simple: [1,2,3,4], smooth: 3.14 }
  end

  describe "POST /pipelines" do
    let(:params) do
      {
        "jobs" => ["encode"],
        "encode" => {
          "media_uid" => "a03qq7",
          "callbacks" => {
            "mp4" => {
              "url" => ""
            },
            "mp3" => {
              "url" => ""
            },
            "compressed_mp4" => {
              "url" => ""
            }
          },
          "source" => {
            "url" => "",
            "filename" => ""
          },
          "type" => "upload",
          "project_uid" => "abc123"
        }
      }
    end

    let(:expected_response) do
      Timecop.freeze(time) do
        Graphene::PipelineSerializer.new(Graphene::Pipeline.first).to_json
      end
    end

    before do
      request.headers.merge!(headers)

      Timecop.freeze(time) do
        post :create, params: params
      end
    end

    it "returns the correct response" do
      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
    end

    it "creates a pipeline" do
      expect(Graphene::Pipeline.count).to eq(1)
      expect(Graphene::Pipeline.first.params).to eq(params)
    end

    it "enqueues a visitor job for the pipeline" do
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
      expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([Graphene::Pipeline.first.to_global_id.to_s])
    end

    it "adds a request params audit" do
      expect(Graphene::Pipeline.first.audits.count).to eq(1)
    end
  end

  describe "PUT /pipelines/:id" do
    let(:expected_response) do
      Timecop.freeze(time) do
        Graphene::PipelineSerializer.new(Graphene::Pipeline.first).to_json
      end
    end

    let(:pipeline) do
      create(:pipeline, params: attributes_for(:pipeline).fetch(:params).merge(one: "two"))
    end

    before do
      request.headers.merge!(headers)
      Timecop.freeze(time) do
        put :update, params: attributes_for(:pipeline).fetch(:params).merge(id: pipeline.id, foo: "bar", one: nil)
      end
      pipeline.reload
    end

    it "updates the pipeline params" do
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
      expect(pipeline.params.fetch("one")).to eq(nil)
      expect(pipeline.params.fetch("foo")).to eq("bar")
    end

    it "adds a request params audit" do
      expect(pipeline.audits.count).to eq(2)
    end
  end

  describe "GET /pipelines/:id" do
    context "ok" do
      let(:expected_response) do
        Timecop.freeze(time) do
          Graphene::PipelineSerializer.new(Graphene::Pipeline.first).to_json
        end
      end

      let(:pipeline) { create(:pipeline) }
      let(:job) { pipeline.children.first }

      before do
        pipeline.add_graph([Jobs::Simple]).each(&:save!)
        pipeline.children.first.fail!(StandardError.new("foobar"))
        request.headers.merge!(headers)
        Timecop.freeze(time) do
          get :show, params: { id: pipeline.id }
        end
      end

      it "returns the correct response" do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
      end
    end

    context "not found" do
      before do
        request.headers.merge!(headers)
        get :show, params: { id: 42 }
      end

      it "returns 404" do
        expect(response.status).to eq(404)
      end
    end
  end

  describe "GET /pipelines/:id/locked" do
    let(:pipeline) { create(:pipeline) }

    let(:expected_response) do
      {
        pipeline_id: pipeline.id,
        is_locked: is_locked
      }.to_json
    end

    before do
      pipeline.add_graph([Jobs::Simple]).each(&:save!)
      child_state
      request.headers.merge!(headers)
      Timecop.freeze(time) do
        get :locked, params: { id: pipeline.id }
      end
    end

    context "is not locked" do
      let(:child_state) { pipeline.children.first.complete! }
      let(:is_locked) { false }

      it "returns false" do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
      end
    end

    context "is locked" do
      let(:child_state) { pipeline.children.first.in_progress! }
      let(:is_locked) { true }

      it "returns true" do
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
      end
    end
  end

  describe "PUT /pipelines/:id/cancel" do
    let(:expected_response) do
      Timecop.freeze(time) do
        Graphene::PipelineSerializer.new(Graphene::Pipeline.first).to_json
      end
    end

    let(:pipeline_params) do
      {
        jobs: %w[simple smooth],
        simple: { data: data },
        smooth: { data: data },
        callbacks: [{}]
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :in_progress, pipeline: pipeline)
    end

    let!(:smooth_job) do
      create(:job, :smooth, state: :pending, pipeline: pipeline)
    end

    before do
      request.headers.merge!(headers)
      Timecop.freeze(time) do
        put :cancel, params: { id: pipeline.id }
      end
      pipeline.reload
    end

    it "cancels the pipeline" do
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq(JSON.parse(expected_response))
      expect(JSON.parse(response.body)["state"]).to eq("cancelled")
      expect(pipeline.jobs.map(&:state).uniq).to eq([:cancelled])
    end

    it "adds a request params audit" do
      expect(pipeline.audits.count).to eq(1)
    end
  end
end
