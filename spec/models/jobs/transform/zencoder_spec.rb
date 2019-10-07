# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Transform::Zencoder do
  subject { create(:job, :encode, state: :in_progress) }

  let(:video_url) { "https://content-proxy-prod-us-west-1.bigsofa.co.uk/tbs-production-us-west-1/uploads/video/video/f197944b-d72e-4470-b376-26e1f87708bc/encoded/8a3c47b1-f5da-4a2f-9e1c-e6940fbf5605.mp4?signature=3058fd0034b0f94a5761a31b63719a60cf860244ec0c95cb6f6e5c08a12361fb&expires=1563963779" }

  describe "#process" do
    before do
      subject.pipeline.update_params!(
        jobs: ["zencoder"],
        zencoder: {
          media_uid: TEST_MEDIA_UID,
          encoding_timeout: 10,
          encoding_check_every: 0.01,
          source: {
            url: video_url,
            filename: "video.mp4"
          },
          type: "upload",
          project_uid: "abc123",
          callbacks: {
            mp4: {
              url: ""
            },
            mp3: {
              url: ""
            },
            compressed_mp4: {
              url: ""
            }
          }
        }
      )

      Timecop.freeze(Time.now)
    end

    after { Timecop.return }

    it "keeps the job marked as in progress" do
      VCR.use_cassette("models/jobs/transform/zencoder/successful", match_requests_on: %i[body uri]) do
        subject.process do |response|
          expect(response).to be_kind_of(Zencoder::Response)
          expect(response).to be_success

          expect(subject.identifier["zencoder_job_id"]).to eq(response.body["id"])

          expect(ZencoderPollJob.jobs.count).to eq(1)
          expect(ZencoderPollJob.jobs.first["args"].length).to eq(2)
          expect(ZencoderPollJob.jobs.first["args"][0]).to eq(subject.id)
          expect(ZencoderPollJob.jobs.first["args"][1]).to be_kind_of(Integer)
          expect(ZencoderPollJob.jobs.first["at"].to_i).to eq((Time.now + 5.seconds).to_i)

          expect(subject).to be_in_progress
        end
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline)
    end
  end
end
