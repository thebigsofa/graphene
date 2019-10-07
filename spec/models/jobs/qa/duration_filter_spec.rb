# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::QA::DurationFilter do
  let(:job) { create(:job, :duration_filter) }

  describe "#process" do
    context "minimum duration ok" do
      before do
        job.pipeline.update_params!(
          jobs: ["duration_filter"],
          duration_filter: {
            minimum_duration: 500,
            media_uid: TEST_MEDIA_UID,
            source: {
              url: VIDEO_SOURCE_URL,
              filename: "video.mp4"
            }
          }
        )
      end

      it "completes the job" do
        VCR.use_cassette("models/jobs/qa/duration_filter/ok") do
          job.process
          expect(job).to be_complete
        end
      end
    end

    context "minimum duration not reached" do
      before do
        job.pipeline.update_params!(
          jobs: ["duration_filter"],
          duration_filter: {
            minimum_duration: 8097,
            media_uid: TEST_MEDIA_UID,
            source: {
              url: IMAGE_SOURCE_URL,
              filename: "video.mp4"
            }
          }
        )
      end

      it "raises an exception" do
        VCR.use_cassette("models/jobs/qa/duration_filter/failure") do
          expect { job.process }.to raise_error(
            Task::HaltError
          ).with_message("Must be at least 8 seconds")
        end
      end
    end
  end
end
