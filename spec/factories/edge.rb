# frozen_string_literal: true

FactoryBot.define do
  factory :edge, class: Graphene::Edge do
    association :origin, factory: :job
    association :destination, factory: :job
  end
end
