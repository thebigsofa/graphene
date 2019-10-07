# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graph::Builder do
  subject { described_class.new(jobs) }

  context "single job" do
    let(:jobs) { ["encode"] }

    let(:expected) do
      [Jobs::Transform::Zencoder]
    end

    it "generates the expected graph" do
      expect(subject.to_graph).to eq(expected)
    end
  end

  context "same priority" do
    let(:jobs) { %w[extract_frames extract_metadata] }

    let(:expected) do
      [
        [
          [Jobs::Process::ExtractFrames],
          [Jobs::Process::ExtractMetadata]
        ]
      ]
    end

    it "generates the expected graph" do
      expect(subject.to_graph).to eq(expected)
    end
  end

  context "mixed priorities" do
    let(:jobs) do
      %w[
        extract_frames
        generate_thumbnails
        duplicate_filter
        adult_content_filter
        activity_detection
        people_detection
        behavioural_recognition
        duration_filter
        encode
        extract_metadata
      ]
    end

    let(:expected) do
      [
        [
          [Jobs::QA::DuplicateFilter],
          [Jobs::QA::DurationFilter]
        ],
        Jobs::QA::AdultContentFilter,
        Jobs::Transform::Zencoder,
        [
          [Jobs::Process::AudioActivityDetection],
          [Jobs::Process::VideoActivityDetection],
          [Jobs::Analysis::BehaviouralRecognition],
          [Jobs::Process::ExtractFrames],
          [Jobs::Process::ExtractMetadata],
          [Jobs::Process::GenerateThumbnails],
          [Jobs::Analysis::PeopleDetection]
        ]
      ]
    end

    it "generates the expected graph" do
      expect(subject.to_graph).to eq(expected)
    end

    it "wraps the classes in job templates" do
      job = subject.to_graph.flatten.detect do |j|
        j == Jobs::Process::AudioActivityDetection
      end

      expect(job.group).to eq("activity_detection")
    end
  end
end
