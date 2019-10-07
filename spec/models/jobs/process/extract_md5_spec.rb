# frozen_string_literal: true

RSpec.describe Jobs::Process::ExtractMD5 do
  subject { create(:job, :extract_md5) }

  context "when processing a video" do
    before do
      subject.pipeline.update_params!(
        jobs: ["extract_md5"],
        extract_md5: {
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
        VCR.use_cassette("models/jobs/process/extract_md5/successful") do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "when processing an image" do
    before do
      subject.pipeline.update_params!(
        jobs: ["extract_md5"],
        extract_md5: {
          media_uid: TEST_IMAGE_UID,
          source: {
            url: IMAGE_SOURCE_URL,
            filename: "video.mp4"
          }
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/extract_md5/image_successful") do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline_gpu)
    end
  end
end
