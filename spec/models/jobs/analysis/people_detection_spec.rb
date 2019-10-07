# frozen_string_literal: true

require "spec_helper"
RSpec.describe Jobs::Analysis::PeopleDetection do
  subject { create(:job, :people_detection) }

  let(:job_id) { "fd46fc58-9edc-436d-a271-28deef994ac5" }

  before do
    subject.pipeline.update_params!(
      jobs: ["people_detection"],
      "people_detection" => {
        "people_detection" => {
          "client" => {
            "id" => 1
          },
          "project" => {
            "uid" => "6fba88"
          },
          "media" => {
            "uid" => "be4477",
            "type" => "Video",
            "md5" => nil,
            "zone" => "eu-west-1",
            "assets" => {
              "mp3" => "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/ec08f538-b10d-422e-97b9-1eb821b6a8d5/encoded/d62c14df-36fa-4888-a597-9d9b3a056c61.mp3?signature=871f37a1471203b6dcbee6a303756ecfbeead121cadcea0d619a39e1cf4849de&expires=1549470683",
              "mp4" => "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/ec08f538-b10d-422e-97b9-1eb821b6a8d5/encoded/d62c14df-36fa-4888-a597-9d9b3a056c61.mp4?signature=870b6ad8956d11495eda8e44ea74278b9064738f4be0f65795bd4f1b7b4899da&expires=1549470692"
            }
          },
          "callback_url" => "https://pipeline-staging-eu-west-1.bigsofa.co.uk/callbacks/ulam",
          "output_url" => ""
        }
      }
    )
  end

  context "#process" do
    it "has a job_id artifact" do
      VCR.use_cassette("models/jobs/process/people_detection/ok") do
        subject.process
        expect(subject.identifier).to eq("people_detection_job_id" => job_id)
      end
    end
  end

  describe "callback response" do
    let(:response) do
      {
        status: "Success",
        summary: {
          detections: {
            '1_probable': {
              'coco:0:person': 0.6689833402633667
            },
            '5_hinted': {
              'coco:26:handbag': 0.17335140705108643,
              'coco:62:tvmonitor': 0.14746832847595215,
              'coco:39:bottle': 0.14543859660625458,
              'coco:28:suitcase': 0.18859396874904633
            },
            '3_possible': {
              'coco:63:laptop': 0.3286844789981842,
              'coco:33:kite': 0.39541497826576233
            },
            '2_likely': {
              'coco:56:chair': 0.49336087703704834
            },
            '4_indicated': {
              'coco:24:backpack': 0.2317323237657547,
              'coco:60:diningtable': 0.26524657011032104
            },
            '6_spurious': {
              'omw:05217168-n': 0.10077516005840154,
              'coco:73:book': 0.10545714199542999,
              'coco:66:keyboard': 0.12838518619537354
            }
          }
        },
        media_uid: "df43gt",
        job_id: 12_345_678,
        errors: [{
          error: "Upload::Error",
          message: "could not upload to ..."
        }]
      }
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline)
    end
  end
end
