# frozen_string_literal: true

require "spec_helper"

RSpec.describe PipelinesController, :with_auth_token, type: :controller do
  let(:time) { Time.now }

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
        PipelineSerializer.new(Pipeline.first).to_json
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
      expect(Pipeline.count).to eq(1)
      expect(Pipeline.first.params).to eq(params)
    end

    it "enqueues a visitor job for the pipeline" do
      expect(SidekiqVisitor.jobs.count).to eq(1)
      expect(SidekiqVisitor.jobs.first["args"]).to eq([Pipeline.first.to_global_id.to_s])
    end

    it "adds a request params audit" do
      expect(Pipeline.first.audits.count).to eq(1)
    end
  end

  describe "PUT /pipelines/:id" do
    let(:expected_response) do
      Timecop.freeze(time) do
        PipelineSerializer.new(Pipeline.first).to_json
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
          PipelineSerializer.new(Pipeline.first).to_json
        end
      end

      let(:pipeline) { create(:pipeline) }
      let(:job) { pipeline.children.first }

      before do
        pipeline.add_graph([Jobs::Transform::Zencoder]).each(&:save!)
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
      pipeline.add_graph([Jobs::Transform::Zencoder]).each(&:save!)
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
        PipelineSerializer.new(Pipeline.first).to_json
      end
    end

    let(:pipeline_params) do
      {
        jobs: %w[
          video_activity_detection
          extract_md5
        ],
        video_activity_detection: {
          media_uid: TEST_MEDIA_UID,
          video_detection_threshold: 0.000027,
          video_collation_threshold: 0.5
        },
        extract_md5: {
          media_uid: TEST_MEDIA_UID,
          source: {
            url: "http://localhost:3000/api/v2/sidecar/redirect?file=media&signature=ee26429e5f566ac48b5d63c4684efb965a90e8c8482e11e95a1600c09f39ea2b&type=media&uid=893556&url_format=standard",
            filename: "video.mp4"
          }
        },
        callbacks: [{}]
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:video_activity_detection_job) do
      create(:job, :video_activity_detection, state: :in_progress, pipeline: pipeline)
    end

    let!(:extract_md5_job) do
      create(:job, :extract_md5, state: :pending, pipeline: pipeline)
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
