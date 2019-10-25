# frozen_string_literal: true

FactoryBot.define do
  factory :pipeline, class: Graphene::Pipeline do
    params do
      media_uid = SecureRandom.uuid.split("-").last

      {
        media_uid: media_uid,
        jobs: []
      }
    end

    transient do
      audit_params do
        {
          "media_uid" => "a03qq7",
          "jobs" => ["encode"],
          "controller" => "pipelines",
          "action" => "create",
          "pipeline" => {}
        }
      end

      audit_timestamp { Time.now }

      audit do
        {
          "params" => audit_params,
          "timestamp" => audit_timestamp
        }
      end
    end

    before(:create) do |pipeline, evaluator|
      pipeline.audits = pipeline.audits.push(evaluator.audit)
    end
  end
end
