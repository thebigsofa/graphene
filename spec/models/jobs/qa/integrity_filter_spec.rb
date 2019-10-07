# frozen_string_literal: true

RSpec.describe Jobs::QA do
  subject { create(:job, :integrity_filter) }

  before do
    subject.pipeline.update_params!(
      jobs: ["integrity_filter"],
      integrity_filter: {
        media_uid: TEST_MEDIA_UID,
        source: {
          url: VIDEO_SOURCE_URL,
          filename: "video.mp4"
        }
      }
    )
  end

  describe "#process" do
    before do
      VCR.use_cassette("models/jobs/qa/integrity_filter/successful") do
        subject.process
      end
    end

    it "completes the job" do
      expect(subject).to be_complete
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline_gpu)
    end
  end
end
