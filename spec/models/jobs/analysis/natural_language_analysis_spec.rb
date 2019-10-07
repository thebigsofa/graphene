# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Analysis::NaturalLanguageAnalysis do
  let(:job) { create(:job, :natural_language_analysis) }
  let(:sentence) do
    {
      "start_timecode" => "0",
      "end_timecode" => "3000",
      "content" => "Well, I'm going to have the debate.",
      "sentiment_score" => 0
    }
  end

  before do
    job.pipeline.update_params!(
      jobs: ["natural_language_analysis"],
      natural_language_analysis: {
        transcript: {
          url: "http://localhost:3000/api/v2/media/caaa1c/language_orders/2393?type=TRANSCRIPT_FORMAT",
          headers: {
            Authorization: ""
          }
        },
        callbacks: {
          natural_language_analysis: {
            file_name: "watson_sentiment.json",
            url: "https://content-proxy-staging-eu-west-1.bigsofa.co.uk/tbs-platform-staging/uploads/video/video/c8147cc8-277f-4e0a-bc54-fa8b02a97113/data/sentiment_analysis/archive.zip?signature=f9cfb56bc568b1450d16c78983556ca4928aaa6713b737a5e5b5e8de56b30fb8&expires=1554385121"
          }
        },
        natural_language_analysis_params: natural_language_analysis_params
      }
    )
  end

  describe "#process" do
    let(:natural_language_analysis_params) do
      {
        "sentiment" => true,
        "categories" => true,
        "emotion" => true,
        "keywords" => true,
        "relations" => true,
        "sentence_by_sentence" => true
      }
    end

    it "completes the job" do
      VCR.use_cassette("models/jobs/analysis/natural_language_analysis/successful") do
        job.process
        expect(job).to be_complete
        expect(job.artifacts["categories"]).to be_present
        expect(job.artifacts["emotion"]).to be_present
        expect(job.artifacts["keywords"]).to be_present
        expect(job.artifacts["relations"]).to be_present
        expect(job.artifacts["sentences"].first).to eq(sentence)
        expect(job.artifacts["sentences"].any?).to be_truthy
        expect(job.artifacts["score"]).to eq(0.568019)
        expect(job.artifacts["label"]).to eq("positive")
      end
    end
  end

  describe "selected features" do
    let(:natural_language_analysis_params) do
      {
        "sentiment" => true,
        "categories" => false,
        "emotion" => false,
        "keywords" => false,
        "relations" => true,
        "sentence_by_sentence" => true
      }
    end

    it "completes the job" do
      VCR.use_cassette("models/jobs/analysis/natural_language_analysis/features") do
        job.process
        expect(job).to be_complete
        expect(job.artifacts["categories"]).to_not(be_present)
        expect(job.artifacts["emotion"]).to_not(be_present)
        expect(job.artifacts["keywords"]).to_not(be_present)
        expect(job.artifacts["relations"]).to(be_present)
        expect(job.artifacts["sentences"].first).to eq(sentence)
        expect(job.artifacts["sentences"].any?).to be_truthy
        expect(job.artifacts["score"]).to eq(0.568019)
        expect(job.artifacts["label"]).to eq("positive")
      end
    end
  end

  describe "no sentence_by_sentence" do
    let(:natural_language_analysis_params) do
      {
        "sentiment" => true,
        "categories" => false,
        "emotion" => false,
        "keywords" => false,
        "relations" => true,
        "sentence_by_sentence" => false
      }
    end

    it "completes the job" do
      VCR.use_cassette("models/jobs/analysis/natural_language_analysis/no_sentences") do
        job.process
        expect(job).to be_complete
        expect(job.artifacts["sentences"]).to be_falsey
      end
    end
  end

  describe "#queue" do
    let(:natural_language_analysis_params) do
      {
        "sentiment" => true,
        "categories" => true,
        "emotion" => true,
        "keywords" => true,
        "relations" => true,
        "sentence_by_sentence" => true
      }
    end

    it "has a correct queue" do
      expect(job.queue).to eq(:pipeline)
    end
  end
end
