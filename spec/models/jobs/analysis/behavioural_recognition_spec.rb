# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Analysis::BehaviouralRecognition do
  subject { create(:job, :behavioural_recognition) }
  let(:source) { "https://content-proxy-prod-eu-west-1.bigsofa.co.uk/tbs-production/uploads/video/video/02139688-a658-4104-a112-bdbcc2694c9c/encoded/6caeb4d2-48f7-48c8-a2fb-c70e25b42c7a.long.expiry.url?signature=05527f967f79d4e912cb6e048ccbeb4f5758f9bbc9a63f27594f216d8b5c5baa\u0026expires=1557753240" }
  let(:video_id) { "5cd961461366c0a59b8e20a6" }

  before do
    subject.pipeline.update_params!(
      jobs: ["behavioural_recognition"],
      "behavioural_recognition" => {
        "source" => source
      }
    )
  end

  describe "#process" do
    it "has a video_id artifact" do
      VCR.use_cassette("models/jobs/process/behavioural_recognition/ok") do
        subject.process
        expect(subject.identifier).to eq("behavioural_recognition_video_id" => video_id)
      end
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline)
    end
  end
end
