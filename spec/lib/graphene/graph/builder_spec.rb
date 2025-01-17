# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Graph::Builder do
  subject { described_class.new({}, jobs, mapping_and_priorities: "custom") }

  module Support
    module Jobs
      module QA
        class DuplicateFilter < ::Jobs::Simple
        end

        class DurationFilter < ::Jobs::Simple
        end

        class AdultContentFilter < ::Jobs::Simple
        end
      end

      module Transform
        class Zencoder < ::Jobs::Simple
        end
      end

      module Process
        class VideoActivityDetection < ::Jobs::Simple
        end
        class ExtractFrames < ::Jobs::Simple
        end
        class ExtractMetadata < ::Jobs::Simple
        end
        class GenerateThumbnails < ::Jobs::Simple
        end
        class AudioActivityDetection < ::Jobs::Simple
        end
      end

      module Analysis
        class BehaviouralRecognition < ::Jobs::Simple
        end

        class PeopleDetection < ::Jobs::Simple
        end
      end
    end
  end

  class CustomMappingAndPriorities
    MAPPING = {
      "duplicate_filter" => [
        [Support::Jobs::QA::DuplicateFilter]
      ],

      "duration_filter" => [
        [Support::Jobs::QA::DurationFilter]
      ],

      "adult_content_filter" => [
        [Support::Jobs::QA::AdultContentFilter]
      ],

      "encode" => [
        [Support::Jobs::Transform::Zencoder]
      ],

      "extract_frames" => [
        [Support::Jobs::Process::ExtractFrames]
      ],

      "extract_metadata" => [
        [Support::Jobs::Process::ExtractMetadata]
      ],

      "generate_thumbnails" => [
        [Support::Jobs::Process::GenerateThumbnails]
      ],

      "activity_detection" => [
        [Support::Jobs::Process::AudioActivityDetection],
        [Support::Jobs::Process::VideoActivityDetection]
      ],
      "people_detection" => [
        [Support::Jobs::Analysis::PeopleDetection]
      ],
      "behavioural_recognition" => [
        [Support::Jobs::Analysis::BehaviouralRecognition]
      ]
    }.freeze

    PRIORITIES = {
      "duplicate_filter" => 1,
      "duration_filter" => 1,

      "adult_content_filter" => 2,

      "encode" => 3,

      "extract_frames" => 4,
      "extract_metadata" => 4,
      "generate_thumbnails" => 4,
      "activity_detection" => 4,
      "people_detection" => 4,
      "behavioural_recognition" => 4
    }.freeze

    def mapping
      MAPPING
    end

    def priorities
      PRIORITIES
    end
  end

  before do
    Graphene.config.mappings_and_priorities["custom"] = CustomMappingAndPriorities.new
  end

  context "single job" do
    let(:jobs) { ["encode"] }

    let(:expected) do
      [Support::Jobs::Transform::Zencoder]
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
          [Support::Jobs::Process::ExtractFrames],
          [Support::Jobs::Process::ExtractMetadata]
        ]
      ]
    end

    it "generates the expected graph" do
      expect(subject.to_graph).to eq(expected)
    end
  end

  context "single job, grouped" do
    let(:jobs) { ["activity_detection"] }

    let(:expected) do
      [
        [
          [Support::Jobs::Process::AudioActivityDetection],
          [Support::Jobs::Process::VideoActivityDetection]
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
          [Support::Jobs::QA::DuplicateFilter],
          [Support::Jobs::QA::DurationFilter]
        ],
        Support::Jobs::QA::AdultContentFilter,
        Support::Jobs::Transform::Zencoder,
        [
          [Support::Jobs::Process::AudioActivityDetection],
          [Support::Jobs::Process::VideoActivityDetection],
          [Support::Jobs::Analysis::BehaviouralRecognition],
          [Support::Jobs::Process::ExtractFrames],
          [Support::Jobs::Process::ExtractMetadata],
          [Support::Jobs::Process::GenerateThumbnails],
          [Support::Jobs::Analysis::PeopleDetection]
        ]
      ]
    end

    it "generates the expected graph" do
      expect(subject.to_graph).to eq(expected)
    end

    it "wraps the classes in job templates" do
      activity_detection_job = subject.to_graph.flatten.find do |job|
        job == Support::Jobs::Process::AudioActivityDetection
      end

      expect(activity_detection_job.group).to eq("activity_detection")
    end
  end
end
