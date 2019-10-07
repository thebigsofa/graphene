# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Process::ExtractFrames do
  subject { create(:job, :extract_frames) }

  before do
    subject.pipeline.update_params!(
      jobs: ["extract_frames"],
      extract_frames: {
        source: {
          url: VIDEO_SOURCE_URL,
          filename: "video.mp4"
        },
        callbacks: {
          frames: {
            file_name: "archive.zip",
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/253/data/frames/archive.zip?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
          }
        }
      }
    )
  end

  describe "#json_schema_properties" do
    let(:expected) do
      {
        extract_frames: {
          type: :object,
          properties: {
            source: {
              not: {
                type: :null
              }
            },
            frame_interval: {
              not: {
                type: :null
              }
            },
            callbacks: {
              not: {
                type: :null
              }
            }
          },
          required: %i[
            source
            callbacks
          ]
        }
      }
    end

    it "returns the correct structure" do
      expect(subject.json_schema_properties).to eq(expected)
    end
  end

  describe "#process" do
    let(:tmpdir) { File.join("spec", "tmp") }

    before do
      FileUtils.mkdir_p(tmpdir)
      allow(Dir).to receive(:mktmpdir).and_return(tmpdir)
    end

    it "completes the jobs" do
      VCR.use_cassette("models/jobs/process/extract_frames/successful") do
        subject.process
        expect(subject.reload).to be_complete
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline_gpu)
    end
  end
end
