# frozen_string_literal: true

RSpec.describe Jobs::Process::ExtractMetadata do
  subject { create(:job, :extract_metadata) }

  before do
    subject.pipeline.update_params!(
      jobs: ["extract_metadata"],
      extract_metadata: {
        media_uid: TEST_MEDIA_UID,
        source: {
          url: VIDEO_SOURCE_URL,
          filename: "video.mp4"
        },
        callbacks: {
          metadata: {
            file_name: "metadata.json",
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/253/data/metadata/metadata.json?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
          }
        }
      }
    )
  end

  describe "#process" do
    before do
      VCR.use_cassette("models/jobs/process/extract_metadata/successful") do
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
