# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::QA::BlacklistFilter do
  let(:job) { create(:job, :blacklist_filter) }

  describe "#process" do
    before do
      job.pipeline.update_params!(
        jobs: ["blacklist_filter"],
        blacklist_filter: {
          media_uid: "cc76b7",
          source: {
            url: VIDEO_SOURCE_URL,
            filename: "video.mp4"
          }
        }
      )
    end

    it "raises an exception if the media has been blacklisted" do
      VCR.use_cassette("models/jobs/qa/blacklist_filter/ok") do
        expect { job.process }.to raise_error(Tasks::Filters::BlacklistedMediaFilter::BlacklistError)
      end
    end
  end
end
