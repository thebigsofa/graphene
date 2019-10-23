# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipelines::Update do
  subject { described_class.new(pipeline, params) }

  let(:data) do
    { simple: [1, 2, 3, 4], smooth: 3.14 }
  end

  context "valid parameters" do
    let(:pipeline) { create(:pipeline) }

    let(:params) do
      { foo: "bar" }
    end

    let(:result) { subject.call }

    it "updates the pipeline params" do
      expect(result).to eq(true)
      expect(pipeline.params["foo"]).to eq("bar")
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
    end
  end

  context "invalid parameters" do
    let(:pipeline_params) do
      {
        jobs: ["simple"],
        simple: { data: data }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        simple: { data: nil }
      }
    end

    let(:result) { subject.call }

    before do
      pipeline.children.reset
    end

    it "does not save the changes" do
      expect(result).to eq(false)
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      expect(pipeline.reload.params.dig("simple", "data", "simple")).to eq([1, 2, 3, 4])
    end
  end

  context "parameters with dependent jobs" do
    let(:new_data) do
      { simple: [0], smooth: 9.84 }
    end

    let(:pipeline_params) do
      {
        jobs: %w[simple smooth],
        simple: new_data,
        smooth: { data: data }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :complete, pipeline: pipeline)
    end

    let!(:smooth_job) do
      create(:job, :smooth, state: :failed, pipeline: pipeline)
    end

    let!(:child_job) do
      create(:job, state: :complete, parents: [simple_job], pipeline: pipeline)
    end

    let(:params) do
      {
        simple: { data: data }
      }
    end

    let(:result) { subject.call }

    before do
      pipeline.children.reset
    end

    it "marks jobs with changed params as pending" do
      expect(result).to eq(true)
      expect(simple_job.reload).to be_pending
      expect(child_job.reload).to be_pending
      expect(smooth_job.reload).to be_failed
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
      expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([pipeline.to_global_id.to_s])
    end
  end

  context "updating pipeline with incomplete jobs" do
    let(:pipeline) do
      create(:pipeline)
    end

    let!(:video_activity_detection_job) do
      create(:job, state: :in_progress, pipeline: pipeline)
    end

    let(:params) do
      { foo: "bar" }
    end

    let(:result) { subject.call }

    it "does not save the changes" do
      expect(result).to eq(false)
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
    end
  end

  context "updating pipeline with new jobs" do
    let(:pipeline_params) do
      {
        jobs: ["simple"],
        simple: {
          data: data
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[simple smooth],
        smooth: {
          data: data
        }
      }
    end

    let(:result) { subject.call }

    it "creates a new graph version" do
      expect(result).to eq(true)
      expect(pipeline.version).to eq(2)
      expect(pipeline.jobs.count).to eq(2)
      expect(pipeline).to be_persisted
      expect(pipeline.jobs.all?(&:persisted?)).to eq(true)

      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
      expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([pipeline.to_global_id.to_s])

      # Can't use the cached jobs here since we've created new job versions with new UUIDs
      simple = pipeline.jobs.detect { |j| j.class == Jobs::Simple }
      expect(simple.version).to eq(2)
      expect(simple).to be_complete

      smooth = pipeline.jobs.detect { |j| j.class == Jobs::Smooth }
      expect(smooth.version).to eq(2)
      expect(smooth).to be_pending
    end
  end

  context "updating pipeline with new jobs but missing params" do
    let(:pipeline_params) do
      {
        jobs: ["simple"],
        simple: { data: data }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[simple smooth]
      }
    end

    let(:result) { subject.call }

    it "does not persist the new graph" do
      expect(result).to eq(false)
    end
  end

  context "updating pipeline with new jobs but invalid parameters" do
    let(:pipeline_params) do
      {
        jobs: ["simple"],
        simple: {
          data: data
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, group: "simple", state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[simple smooth],
        smooth: {
          data: data
        },
        simple: {
          data: nil
        }
      }
    end

    let(:result) { subject.call }

    it "creates a new graph version" do
      expect(result).to eq(false)

      pipeline.reload

      expect(pipeline.version).to eq(1)
      expect(pipeline.jobs.count).to eq(1)

      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
    end
  end

  context "removes job which failed (retry pipeline)" do
    let(:pipeline_params) do
      {
        jobs: %w[simple smooth unite_data],
        simple: {
          data: data
        },
        smooth: {
          data: data
        },
        unite_data: {
          data: data
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:jobs) do
      create(:job, :simple, state: :complete, pipeline: pipeline)
      create(:job, :smooth, state: :failed, pipeline: pipeline)
      create(:job, :unite_data, state: :failed, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[simple unite_data]
      }
    end

    let(:result) { subject.call }

    it "resets all job errors and updates pipeline version" do
      expect(pipeline.params["jobs"].count).to eq(3)
      expect(pipeline.version).to eq(1)

      expect(result).to eq(true)

      pipeline.reload
      pipeline.jobs.each do |job|
        expect(job.error).to eq(nil)
        expect(job.error_message).to eq(nil)
      end

      expect(pipeline.params["jobs"].count).to eq(2)
      expect(pipeline.version).to eq(2)
    end
  end
end
