# frozen_string_literal: true

RSpec.describe Jobs::Process::PrepareDownload do
  subject { create(:job, :prepare_download) }

  context "with multiple sources" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-prod-tbsgb-1.bigsofa.co.uk/tbs-production/uploads/video_clip/clip/31553/encoded/8d27ccf0-4cd5-4746-b63e-9b90a34f422e_13_to_26.mp4?signature=f4e3ede998393d86ac29b28506a2ba0a481a9446ca664e36a1763cc53e0decc3&expires=1551102588#t=",
              file_name: "sausage.mp4",
              subtitle: {
                url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=0&end_time=8000",
                headers: { Authorization: "" },
                file_name: "sausage.srt"
              }
            },
            {
              url: "https://content-proxy-prod-tbsgb-1.bigsofa.co.uk/tbs-production/uploads/video_clip/clip/31670/encoded/06a0bffe-90bd-4035-9b1a-85269fb6f2d2_9_to_30.mp4?signature=fc5c64393347e97ccd68b3530443fd813b1fd6a58d0fdf015b30e8d17e20f9da&expires=1551103374#t=",
              file_name: "bacon.mp4",
              subtitle: {
                url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=0&end_time=8000",
                headers: { Authorization: "" },
                file_name: "sausage.srt"
              }
            },
            {
              url: "https://content-proxy-prod-tbsgb-1.bigsofa.co.uk/tbs-production/uploads/video_clip/clip/31626/encoded/32b73af7-1ae0-458d-9438-50dee1c53483_6_to_24.mp4?signature=3fefdb5d2078bae82cec556b3c1061b5474788395938cd973b6607bda1614ce3&expires=1551103388#t=",
              file_name: "hash_brown.mp4"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/download/file/93/embed-test.mp4?signature=72e52c1575c8ef2633284552b31b32d465b2ff2934205861130ec2ba68e79335&expires=1551103428",
              file_name: "my_download.zip"
            }
          },
          join: false
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/clips_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with multiple sources including txt" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          join: false,
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/69369468-e607-485d-b5c4-3bfe16d995d8/encoded/10226cda-ccaf-4dc0-a4b8-abcccf3998b5.mp4?signature=5d6886a76872600f6bdebf5dd1b54499ced777cabcf56a22d3d3a6541147daad&expires=1552052072",
              end_time: nil,
              file_name: "2b4f25b5-6147-40a7-898a-7c9e712a368f-compressed-mp4.mp4",
              start_time: nil
            },
            {
              url: "https://platform-staging.bigsofa.co.uk/api/v2/media/d23fb3/language_orders/2379?type=txt",
              headers: {
                Authorization: ""
              },
              file_name: "2b4f25b5-6147-40a7-898a-7c9e712a368f-compressed-mp4.txt"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/download/file/538/2b4f25b5-6147-40a7-898a-7c9e712a368f-compressed-mp4.zip?signature=3c88f44394d1abc4be9a6e7ca655cf7b527cea617cd4ff6ba403e72f1878a231&expires=1551450872",
              file_name: "2b4f25b5-6147-40a7-898a-7c9e712a368f-compressed-mp4.zip"
            }
          }
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/txt_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "joined with transcripts" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video_clip/clip/8851/encoded/f59ab662-3343-473c-89df-8b13fe9bcceb_0_to_10.mp4?signature=194c124370f657f3e0cb27743db594c644f08c7ddf4991263a1449a3ce59e7ea&expires=1550766473#t=",
              file_name: "sausage.mp4"
            },
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video_clip/clip/8850/encoded/f802298f-646d-4283-b86a-10a3e71e7257_1_to_41.mp4?signature=a96f50cbddb974de72a838e78ed1506ec825b238bac17cb069f6f71a290af235&expires=1550767379#t=",
              file_name: "bacon.mp4"
            },
            {
              url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=1&end_time=20000",
              headers: { Authorization: "" },
              file_name: "sausage.srt"
            },
            {
              url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=1&end_time=20000",
              headers: { Authorization: "" },
              file_name: "bacon.srt"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/download/file/390/sofa-list-1.mp4?signature=d1e8bd847db4025f3dd8bbc91b9900f988341f3ee10b121b4c21a304cdeada5e&expires=1550683929",
              file_name: "my_download.zip"
            }
          },
          join: true
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/join_transcripts_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with multiple sources joined" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/c01beb26-8b07-4719-8b06-12d14baf10c7/e6b8e9d7-7a71-418f-bc31-62d110c236d6.mp4?signature=d0ff6a863352cdd13aea35e789cef12603734a8ec2c82b5057e0223660bcd09e&expires=1550331566",
              file_name: "sausage.mp4"
            },
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/74b6c443-8fc3-491f-a565-d5825b172bb0/40f18a21-25bb-4105-ba7c-d51bb1906152.mp4?signature=45810ff4d1b8b35c08763287e03c6be3a6f15fd87dff28517f24903218d31e01&expires=1550331661",
              file_name: "bacon.mp4"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/85c943c5-be68-4e75-bf73-7488cb2246ec/981700b4-978d-40fe-86aa-4802e523693f.mp4?signature=dfc20f168f0dbb7190e9e5b779728d1c47d16cc76f38f1ca367de8d592229fff&expires=1549628004",
              file_name: "my_download.mp4"
            }
          },
          join: true
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/joined_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with one source" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/3140ac60-59d8-4c60-bc18-3e94aed07b9b/f34f4125-c2fd-49cf-a3e3-66f443a62de6.mp4?signature=4b6883b268ecdaf85db83c8bdd63f547c16d36220a0a666f6fbead1ea57a35ea&expires=1549629003",
              file_name: "sausage.mp4"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/3140ac60-59d8-4c60-bc18-3e94aed07b9b/f34f4125-c2fd-49cf-a3e3-66f443a62de6.mp4?signature=26daca5effcbbe2ab864ddd08a1f33ad75f775408c2e85d53d59529717744851&expires=1549629027",
              file_name: "my_download.mp4"
            }
          },
          join: false
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/single_file_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with clipping" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/3140ac60-59d8-4c60-bc18-3e94aed07b9b/f34f4125-c2fd-49cf-a3e3-66f443a62de6.mp4?signature=cb2dee8424c1b9144f8e9b1f65ce2bad3df9f6477da216582dfe83b046d203e1&expires=1549636617",
              start_time: 1000,
              end_time: 3000,
              file_name: "sausage.mp4"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/3140ac60-59d8-4c60-bc18-3e94aed07b9b/f34f4125-c2fd-49cf-a3e3-66f443a62de6.mp4?signature=d4f2f9ff241f9124673eee066b9214f0f3da7420e7dc7dc3482491f3b4d33ab6&expires=1549636641",
              file_name: "my_download.mp4"
            }
          },
          join: false
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/clipped_file_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with subtitles" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/c01beb26-8b07-4719-8b06-12d14baf10c7/e6b8e9d7-7a71-418f-bc31-62d110c236d6.mp4?signature=842f726c3bdeb91d15365ab101c0d50e9f7206d26e6879b5c0d18f8b58104fc4&expires=1550314117",
              start_time: 1000,
              end_time: 3000,
              file_name: "sausage.mp4",
              subtitle: {
                url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=0&end_time=8000",
                headers: { Authorization: "" },
                file_name: "sausage.srt"
              }
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/download/file/21/2b4f25b5-6147-40a7-898a-7c9e712a368f-compressed-mp4.zip?signature=ecf4e2247d320649a302026d60c00817d76f349d158aeaa97148d71b1cf26857&expires=1550312822",
              file_name: "my_download.mp4"
            }
          },
          join: true
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/subtitled_file_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end

    describe "#with empty transcript content" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/empty_transcript", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
        expect(subject).to be_complete
      end
    end
  end

  context "with headers" do
    before do
      subject.pipeline.update_params!(
        jobs: ["prepare_download"],
        prepare_download: {
          sources: [
            {
              url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=srt&start_time=1&end_time=20000",
              headers: { Authorization: "" },
              file_name: "sausage.srt"
            }
          ],
          callbacks: {
            file: {
              url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/download/file/5/clipped-test.mp4?signature=15f557456af10fb4ed466033d60809df5aa0d3adea3df1a351822bf91b745228&expires=1550148522",
              file_name: "my_download.srt"
            }
          },
          join: false
        }
      )
    end

    describe "#process" do
      before do
        VCR.use_cassette("models/jobs/process/prepare_download/download_transcript_successful", preserve_exact_body_bytes: true) do
          subject.process
        end
      end

      it "completes the job" do
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
