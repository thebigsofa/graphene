# frozen_string_literal: true

module Graphene
  module Tracking
    class Disabled
      include Sidekiq::Worker
      include Sidekiq::Throttled::Worker

      attr_reader :queue
      sidekiq_options(queue: :pipeline_tracking, backtrace: true)

      def perform(queue)
        ::Sidekiq.logger.info(
          "Sidekiq tracking is disabled. Implement your own... bitch."
        )
      end
    end
  end
end
