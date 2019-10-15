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
        set_values
        perform
      end

      private

      def perform
        Graphene.config.sidekiq_tracker.perform_in(10.seconds, name) unless too_many_jobs?
      end

      def too_many_jobs?
        tracking_queue.size >= 100
      end

      def tracking_queue
        @tracking_queue ||= Sidekiq::Queue.new("pipeline_tracking")
      end

      def set_values
        Redis.current.hmset(:queue_data, name, [latency, queue_size].to_json)
      end

      def queue_size
        sidekiq_queue.size
      end

      def sidekiq_queue
        @sidekiq_queue ||= Sidekiq::Queue.new(queue)
      end

      def name
        sidekiq_queue.name
      end

      def latency
        sidekiq_queue.latency
      end
    end
  end
end
