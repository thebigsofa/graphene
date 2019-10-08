# frozen_string_literal: true

FactoryBot.define do
  factory :job, class: Graphene::Jobs::Base do
    association :pipeline, factory: :pipeline

    # trait :encode do
    #   initialize_with { Jobs::Transform::Zencoder.new(attributes) }

    #   after(:create) do |job, _|
    #     unless job.pending?
    #       artifacts = {}.merge(job.artifacts)

    #       identifier = {
    #         zencoder_job_id: Random.rand(999_999)
    #       }.merge(job.identifier)

    #       job.update!(artifacts: artifacts)
    #       job.update!(identifier: identifier)
    #     end
    #   end
    # end

    trait :fail do
      initialize_with { Graphene::Jobs::Fail.new(attributes) }
    end

    # trait :blacklist_filter do
    #   initialize_with { Jobs::QA::BlacklistFilter.new(attributes) }
    # end

    # trait :skip_encode do
    #   initialize_with { Jobs::Transform::SkipEncode.new(attributes) }
    # end

    # trait :adult_content_filter do
    #   initialize_with { Jobs::QA::AdultContentFilter.new(attributes) }
    # end

    # trait :duplicate_filter do
    #   initialize_with { Jobs::QA::DuplicateFilter.new(attributes) }
    # end

    # trait :duration_filter do
    #   initialize_with { Jobs::QA::DurationFilter.new(attributes) }
    # end

    # trait :extract_metadata do
    #   initialize_with { Jobs::Process::ExtractMetadata.new(attributes) }
    # end

    # trait :extract_md5 do
    #   initialize_with { Jobs::Process::ExtractMD5.new(attributes) }
    # end

    # trait :generate_thumbnails do
    #   initialize_with { Jobs::Process::GenerateThumbnails.new(attributes) }
    # end

    # trait :extract_frames do
    #   initialize_with { Jobs::Process::ExtractFrames.new(attributes) }
    # end

    # trait :prepare_download do
    #   initialize_with { Jobs::Process::PrepareDownload.new(attributes) }
    # end

    # trait :audio_activity_detection do
    #   initialize_with { Jobs::Process::AudioActivityDetection.new(attributes) }
    # end

    # trait :video_activity_detection do
    #   initialize_with { Jobs::Process::VideoActivityDetection.new(attributes) }
    # end

    # trait :people_detection do
    #   initialize_with { Jobs::Analysis::PeopleDetection.new(attributes) }
    # end

    # trait :integrity_filter do
    #   initialize_with { Jobs::QA::IntegrityFilter.new(attributes) }
    # end

    # trait :natural_language_analysis do
    #   initialize_with { Jobs::Analysis::NaturalLanguageAnalysis.new(attributes) }
    # end

    # trait :behavioural_recognition do
    #   initialize_with { Jobs::Analysis::BehaviouralRecognition.new(attributes) }
    # end

    # trait :google_classification_tags do
    #   initialize_with { Jobs::Process::GoogleClassificationTags.new(attributes) }
    # end
  end
end
