# frozen_string_literal: true

require "spec_helper"

RSpec.describe UpdatePipeline do
  subject { described_class.new(pipeline, params) }

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
        jobs: ["video_activity_detection"],
        video_activity_detection: {
          media_uid: TEST_MEDIA_UID,
          video_detection_threshold: 0.000027,
          video_collation_threshold: 0.5
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:video_activity_detection_job) do
      create(:job, :video_activity_detection, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        video_activity_detection: { video_detection_threshold: nil }
      }
    end

    let(:result) { subject.call }

    before do
      pipeline.children.reset
    end

    it "does not save the changes" do
      expect(result).to eq(false)
      expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      expect(pipeline.reload.params.dig("video_activity_detection", "video_detection_threshold")).to eq(0.000027)
    end
  end

  context "parameters with dependent jobs" do
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
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:video_activity_detection_job) do
      create(:job, :video_activity_detection, state: :complete, pipeline: pipeline)
    end

    let!(:extract_md5_job) do
      create(:job, :extract_md5, state: :failed, pipeline: pipeline)
    end

    let!(:child_job) do
      create(:job, state: :complete, parents: [video_activity_detection_job], pipeline: pipeline)
    end

    let(:params) do
      {
        video_activity_detection: {
          video_detection_threshold: 0.00003,
          source: {
            url: "http://localhost:3000/api/v2/sidecar/redirect?file=media&signature=ee26429e5f566ac48b5d63c4684efb965a90e8c8482e11e95a1600c09f39ea2b&type=media&uid=893556&url_format=standard",
            filename: "video.mp4"
          },
          callbacks: [
            {
              url: "http://localhost:3000/api/v2/sidecar/redirect?file=frames&signature=7bcf185b029b2331d29b5f0066f50180402d44d7af31c7f47d115a380156ad6e&type=media&uid=893556&url_format=standard&version=FILENAME",
              replace: "FILENAME"
            }
          ]
        }
      }
    end

    let(:result) { subject.call }

    before do
      pipeline.children.reset
    end

    it "marks jobs with changed params as pending" do
      expect(result).to eq(true)
      expect(video_activity_detection_job.reload).to be_pending
      expect(child_job.reload).to be_pending
      expect(extract_md5_job.reload).to be_failed
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
        jobs: ["encode"],
        encode: {
          media_uid: TEST_MEDIA_UID
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:encode_job) do
      create(:job, :encode, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[encode extract_frames],
        extract_frames: {
          media_uid: TEST_MEDIA_UID,
          source: {
            url: "http://localhost:3000/api/v2/sidecar/redirect?file=media&signature=ee26429e5f566ac48b5d63c4684efb965a90e8c8482e11e95a1600c09f39ea2b&type=media&uid=893556&url_format=standard",
            filename: "video.mp4"
          },
          callbacks: [
            {
              url: "http://localhost:3000/api/v2/sidecar/redirect?file=frames&signature=7bcf185b029b2331d29b5f0066f50180402d44d7af31c7f47d115a380156ad6e&type=media&uid=893556&url_format=standard&version=FILENAME",
              replace: "FILENAME"
            }
          ]
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
      encode = pipeline.jobs.detect { |j| j.class == Jobs::Transform::Zencoder }
      expect(encode.version).to eq(2)
      expect(encode).to be_complete

      encode = pipeline.jobs.detect { |j| j.class == Jobs::Process::ExtractFrames }
      expect(encode.version).to eq(2)
      expect(encode).to be_pending
    end
  end

  context "updating pipeline with new jobs but missing params" do
    let(:pipeline_params) do
      {
        jobs: ["encode"],
        encode: {
          media_uid: TEST_MEDIA_UID
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:encode_job) do
      create(:job, :encode, state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[encode extract_frames]
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
        jobs: ["encode"],
        encode: {
          media_uid: TEST_MEDIA_UID
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:encode_job) do
      create(:job, :encode, group: "encode", state: :complete, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[encode extract_frames],
        extract_frames: {
          media_uid: TEST_MEDIA_UID
        },
        encode: {
          media_uid: nil
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
        jobs: %w[duration_filter duplicate_filter encode],
        duration_filter: {
          minimum_duration: 500,
          media_uid: TEST_MEDIA_UID,
          source: {
            url: VIDEO_SOURCE_URL,
            filename: "video.mp4"
          }
        },
        duplicate_filter: {
          media_uid: TEST_MEDIA_UID
        },
        encode: {
          media_uid: TEST_MEDIA_UID
        }
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:jobs) do
      create(:job, :duration_filter, state: :complete, pipeline: pipeline)
      create(:job, :duplicate_filter, state: :failed, pipeline: pipeline)
      create(:job, :encode, state: :failed, pipeline: pipeline)
    end

    let(:params) do
      {
        jobs: %w[duration_filter encode]
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
