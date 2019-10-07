# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::QA::AdultContentFilter do
  let(:tmpdir) { File.join("spec", "tmp") }
  subject { create(:job, :adult_content_filter) }

  context "When processing a video" do
    before do
      subject.pipeline.update_params!(
        jobs: ["adult_content_filter"],
        adult_content_filter: {
          media_uid: TEST_MEDIA_UID,
          source: {
            url: VIDEO_SOURCE_URL,
            filename: "video.mp4"
          },
          callbacks: {
            adult_content: {
              file_name: "archive.zip",
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/253/data/adult_filter_responses/archive.zip?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
            }
          },
          frame_interval: 5
        }
      )
      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    describe "#process" do
      context "no adult content" do
        it "completes the job" do
          VCR.use_cassette("models/jobs/qa/adult_content_filter/ok") do
            subject.process
            expect(subject).to be_complete
          end
        end
      end

      context "adult content present" do
        it "raises an exception" do
          VCR.use_cassette("models/jobs/qa/adult_content_filter/failure") do
            expect { subject.process }.to raise_error(Task::HaltError)
          end
        end
      end
    end
  end

  context "When processing an image" do
    before do
      subject.pipeline.update_params!(
        jobs: ["adult_content_filter"],
        adult_content_filter: {
          media_uid: TEST_IMAGE_UID,
          source: {
            url: IMAGE_SOURCE_URL,
            filename: "image.jpg"
          },
          callbacks: {
            adult_content: {
              file_name: "archive.zip",
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/image/image/253/data/adult_filter_responses/archive.zip?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
            }
          },
          frame_interval: 5
        }
      )
      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    describe "#process" do
      context "no adult content" do
        it "completes the job" do
          VCR.use_cassette("models/jobs/qa/adult_content_filter/image_ok") do
            subject.process
            expect(subject).to be_complete
          end
        end
      end

      context "adult content present" do
        it "raises an exception" do
          VCR.use_cassette("models/jobs/qa/adult_content_filter/image_failure") do
            expect { subject.process }.to raise_error(Task::HaltError)
          end
        end
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline_gpu)
    end
  end
end
