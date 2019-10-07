# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Process::GoogleClassificationTags do
  let(:tmpdir) { File.join("spec", "tmp") }
  subject { create(:job, :google_classification_tags) }

  context "When processing a video" do
    before do
      subject.pipeline.update_params!(
        jobs: ["google_classification_tags"],
        google_classification_tags: {
          media_uid: TEST_MEDIA_UID,
          source: {
            url: "https://content-proxy-prod-us-west-1.bigsofa.co.uk/tbs-production-us-west-1/uploads/video/video/d28c4db2-7128-4629-b6f2-6b605c0f3e62/encoded/e7b74d5b-db08-4f20-a2fd-3d0e43a2c741.mp4?signature=6fd6c32746ac2f9b96623d5a8ccc220323b8789b318f94f3c180097050b93e8a&expires=1563886803",
            filename: "video.mp4"
          }
        }
      )
      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    describe "#process" do
      it "completes the job" do
        VCR.use_cassette("models/jobs/process/google_classification_tags/ok") do
          subject.process
          expect(subject).to be_complete
        end
      end

      it "stores tags" do
        VCR.use_cassette("models/jobs/process/google_classification_tags/ok") do
          subject.process
          expect(subject.artifacts["google_classification_tags"].count).to eq(11)
          expect(subject.artifacts["google_classification_tags"].first.values.first).to eq("White")
        end
      end
    end
  end

  context "When processing an image" do
    before do
      subject.pipeline.update_params!(
        jobs: ["google_classification_tags"],
        google_classification_tags: {
          media_uid: TEST_IMAGE_UID,
          source: {
            url: "https://content-proxy-prod-us-west-1.bigsofa.co.uk/tbs-production-us-west-1/uploads/image/image/7c43379d-5978-4614-8a09-712b0c50849a/span4_e02dce84-739c-4577-a791-4a3646ea4265.jpg?signature=702ab3d4a7680e573402ce268e59cc3f69b9e88ba7c3711b54d1bb4b79b19a31&expires=1563886926",
            filename: "image.jpg"
          }
        }
      )
      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    describe "#process" do
      it "completes the job" do
        VCR.use_cassette("models/jobs/process/google_classification_tags/image_ok") do
          subject.process
          expect(subject).to be_complete
        end
      end

      it "stores tags" do
        VCR.use_cassette("models/jobs/process/google_classification_tags/image_ok") do
          subject.process
          expect(subject.artifacts["google_classification_tags"].count).to eq(10)
          expect(subject.artifacts["google_classification_tags"].first.values.first).to eq("Sky")
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
