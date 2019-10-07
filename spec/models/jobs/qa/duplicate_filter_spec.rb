# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::QA::DuplicateFilter do
  let(:project_uid) { TEST_PROJECT_UID }
  subject { create(:job, :duplicate_filter) }

  context "When processing a video" do
    before do
      subject.pipeline.update_params!(
        jobs: ["duplicate_filter"],
        duplicate_filter: {
          project_uid: project_uid,
          media_uid: TEST_MEDIA_UID,
          source: {
            url: VIDEO_SOURCE_URL,
            filename: "video.mp4"
          }
        }
      )
    end

    describe "#process" do
      it "raises an exception if the media exists" do
        VCR.use_cassette("models/jobs/qa/duplicate_filter/ok") do
          expect { subject.process }.to raise_error(
            Task::HaltError
          ).with_message("#{TEST_MEDIA_UID} already exists in project #{project_uid}")
        end
      end
    end
  end

  context "When processing an image" do
    before do
      subject.pipeline.update_params!(
        jobs: ["duplicate_filter"],
        duplicate_filter: {
          project_uid: project_uid,
          media_uid: TEST_IMAGE_UID,
          source: {
            url: IMAGE_SOURCE_URL,
            filename: "video.mp4"
          }
        }
      )
    end

    describe "#process" do
      it "raises an exception if the media exists" do
        VCR.use_cassette("models/jobs/qa/duplicate_filter/image_ok") do
          expect { subject.process }.to raise_error(
            Task::HaltError
          ).with_message("#{TEST_IMAGE_UID} already exists in project #{project_uid}")
        end
      end
    end
  end
end
