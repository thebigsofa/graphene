# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Process::AudioActivityDetection do
  subject { create(:job, :audio_activity_detection) }

  let(:time) { TZInfo::Timezone.get("UTC").now.iso8601 }

  let(:expected) do
    {
      "activity_detection" => {
        "audio" => {
          "active" => [[0.0, 1.24]],
          "detection_type" => "audio",
          "inactive" => [],
          "media_length" => 1.24
        }
      }
    }
  end

  before do
    subject.pipeline.update_params!(
      jobs: ["audio_activity_detection"],
      audio_activity_detection: {
        media_uid: TEST_MEDIA_UID,
        audio_detection_threshold: 0.000027,
        audio_collation_threshold: 0.5,
        source: {
          url: VIDEO_SOURCE_URL,
          filename: "video.mp4"
        },
        callbacks: {
          audio: {
            file_name: "audio_activity.json",
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/253/data/activity_detection/audio_activity.json?signature=b1ac5760d1e389114480bfe0ef1772abb1ed2129d3505a616c455233760c25dd&expires=1549151457"
          },
          video: {
            file_name: "video_activity.json",
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/253/data/activity_detection/video_activity.json?signature=bfd6e3122bfefbd3089aa344ba2ad2d972e8f4baddfc4aecc09ac007353fb718&expires=1549151488"
          }
        }
      }
    )
  end

  it "uploads the activity detection json" do
    Timecop.freeze(time) do
      VCR.use_cassette("models/jobs/process/audio_activity_detection/ok") do
        subject.process do |response|
          expect(response).to be_kind_of(Excon::Response)
          expect(response.status).to eq(200)

          subject.artifacts["activity_detection"]["audio"].delete("scanning_data")
          subject.artifacts["activity_detection"]["audio"].delete("source")

          expect(subject.artifacts).to eq(expected)
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
