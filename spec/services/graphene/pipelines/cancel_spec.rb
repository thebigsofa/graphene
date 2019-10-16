# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipelines::Cancel do
  subject { described_class.new(pipeline) }

  context "updating pipeline" do
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

    let(:result) { subject.call }

    it "updates states" do
      expect(result).to eq(true)
      expect(pipeline.jobs.map(&:state).uniq).to eq([:cancelled])
      expect(CallbackNotifierJob.jobs.count).to eq(4)
    end
  end
end
