# frozen_string_literal: true

module Graphene
  module Tracking
    class SidekiqTrackable
      attr_reader :queue

      def initialize(queue)
        @queue = queue.to_s
      end

      def self.call(queue)
        new(queue).call
      end

      def call
        save_queue_data
        perform
      end

      private

      def save_queue_data
        Redis.current.hmset(
          :queue_data, sidekiq_queue.name, [sidekiq_queue.latency, sidekiq_queue.size].to_json
        )
      end

      def perform
        Graphene.config.sidekiq_tracker.perform_in(10.seconds, sidekiq_queue.name) unless too_many_jobs?
      end

      def sidekiq_queue
        @sidekiq_queue ||= Sidekiq::Queue.new(queue)
      end

      def too_many_jobs?
        tracking_queue.size >= 100
      end

      def tracking_queue
        @tracking_queue ||= Sidekiq::Queue.new(Graphene.config.sidekiq_tracker_queue_name)
      end
    end
  end
end
