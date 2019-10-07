# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Transform::SkipEncode do
  subject { create(:job, :skip_encode, state: :in_progress) }

  let(:video_url) { "https://content-proxy-prod-eu-west-1.bigsofa.co.uk/tbs-production/uploads/video/video/53d7f99a-9927-40c5-869c-3393d1d7bf5b/encoded/89a86448-11c4-4d52-9eee-ff1078a643a0.mp4?signature=29b90d7203d4227b257794f94c2159fe715405d0b6ed42d43ef864352bb06748&expires=1568378099" }
  before do
    subject.pipeline.update_params!(
      jobs: ["skip_encode"],
      skip_encode: {
        source: {
          url: video_url,
          filename: "e772d351-9937-4ff8-912c-c3e92ad9a5d8.mp4"
        },
        type: "upload",
        project_uid: "abc123",
        callbacks: {
          mp4: {
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/zencoder/f4f9df0168c5f1edbb2ffa5213a3dba5ca15762be560651029d631e32ae79f82/1570966312/tbs-platform-staging/uploads/video/video/9c0474fe-653b-4d66-bbd6-00abd9a3ed92/encoded/video_1.mp4",
            file_name: "e772d351-9937-4ff8-912c-c3e92ad9a5d8.mp4"
          }
        }
      }
    )

    Timecop.freeze(Time.now)
  end

  describe "#process" do
    after { Timecop.return }

    it "completes" do
      VCR.use_cassette(
        "models/jobs/transform/skip_encode/successful",
        match_requests_on: %i[body uri],
        preserve_exact_body_bytes: true
      ) do
        subject.process
        expect(subject).to be_complete
      end
    end
  end

  describe "#invalid input type" do
    let(:video_url) { "https://content-proxy-prod-eu-west-1.bigsofa.co.uk/tbs-production/uploads/video/video/246/encoded/Mike_Gary_Bankside_14_11_2012.mp3?signature=4ebd4c331ea628bfc702f983c0fbfd2931157d615f036dcf9d5f56fe1317676a&expires=1568379095" }

    it "fails" do
      VCR.use_cassette(
        "models/jobs/transform/skip_encode/fails",
        match_requests_on: %i[body uri],
        preserve_exact_body_bytes: true
      ) do
        expect { subject.process }.to raise_error(
          Task::HaltError
        ).with_message("Video Must be Mp4 to skip encoding")
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline)
    end
  end
end
