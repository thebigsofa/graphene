# frozen_string_literal: true

module Graphene
  class SidekiqTrackingJob
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    sidekiq_options(queue: :pipeline_tracking, backtrace: true)
    sidekiq_throttle(
      # Allow maximum 1 jobs every 10 seconds.
      threshold: { limit: 1, period: 10, key_suffix: ->(queue) { queue } }
    )

    def perform(queue)
      Tracking.const_get(tracker, false).call(queue)
    end

    private

    def tracker
      ENV["INFRA"] || "AWS"
    end
  end
end
