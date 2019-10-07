# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Process::GenerateThumbnails do
  subject { create(:job, :generate_thumbnails) }
  let(:tmpdir) { File.join("spec", "tmp") }

  context "When processing a video" do
    before do
      subject.pipeline.update_params!(
        jobs: ["generate_thumbnails"],
        generate_thumbnails: {
          media_uid: TEST_MEDIA_UID,
          thumbnail_versions: {
            span1: ["resize_to_fit", 122, 51]
          },
          source: {
            url: VIDEO_SOURCE_URL,
            filename: "video.mp4"
          },
          callbacks: {
            span1: {
              command: "resize_to_fit",
              size: [122, 51],
              file_name: "span1_abcd12.jpg",
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/image/253/span1_abcd12.jpg?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
            }
          }
        }
      )

      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    describe "#process" do
      it "completes the job" do
        VCR.use_cassette("models/jobs/process/generate_thumbnails/successful") do
          subject.process
        end

        expect(subject).to be_complete
      end
    end
  end

  context "When processing an image" do
    describe "#process" do
      before do
        subject.pipeline.update_params!(
          jobs: ["generate_thumbnails"],
          generate_thumbnails: {
            media_uid: TEST_IMAGE_UID,
            thumbnail_versions: {
              span1: ["resize_to_fit", 122, 51]
            },
            source: {
              url: IMAGE_SOURCE_URL,
              filename: "video.mp4"
            },
            callbacks: {
              span1: {
                command: "resize_to_fit",
                size: [122, 51],
                file_name: "span1_abcd12.jpg",
                url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/image/253/span1_abcd12.jpg?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
              }
            }
          }
        )

        FileUtils.mkdir_p(tmpdir)
        allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
      end

      it "completes the job" do
        VCR.use_cassette("models/jobs/process/generate_thumbnails/image_successful") do
          subject.process
        end

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
