# frozen_string_literal: true

FactoryBot.define do
  factory :job, class: Graphene::Jobs::Base do
    association :pipeline, factory: :pipeline

    trait :simple do
      initialize_with { Jobs::Simple.new(attributes) }
    end

    trait :smooth do
      initialize_with { Jobs::Smooth.new(attributes) }
    end

    trait :unite_data do
      initialize_with { Jobs::UniteData.new(attributes) }
    end

    trait :fail do
      initialize_with { Graphene::Jobs::Fail.new(attributes) }
    end
  end
end
