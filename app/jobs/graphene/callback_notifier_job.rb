# frozen_string_literal: true

module Graphene
  class CallbackNotifierJob
    include Sidekiq::Worker
    FARRADAY_ERRORS = [::Faraday::ResourceNotFound, ::Faraday::TimeoutError].freeze
    CALLBACK_CLIENT = {
      https: Graphene::CallbackHandlers::Https,
      kafka: Graphene::CallbackHandlers::Kafka
    }.freeze

    sidekiq_options(queue: :pipeline_poll, backtrace: true, retry: false)

    MAX_RETRIES = 5

    def perform(pipeline_id, callback, retries = 0)
      return if Graphene::CallbackAggregate.count_for(pipeline_id) < 1

      Graphene::CallbackAggregate.clear(pipeline_id)

      pipeline = Pipeline.find(pipeline_id)

      CALLBACK_CLIENT[Graphene.config.callback_auth.fetch(:method, :https)].call(
        callback: callback,
        pipeline: pipeline
      )
    rescue *FARRADAY_ERRORS => e
      handle_error(pipeline, callback, e, retries)
    end

    private

    def handle_error(pipeline, callback, error, retries)
      raise error if retries >= MAX_RETRIES

      retry_job(pipeline, callback, error, retries)
    end

    def retry_job(pipeline, callback, error, retries)
      pipeline.aggregate_callback
      self.class.perform_in(5.seconds, pipeline.id, callback, retries + 1)

      # Re-raise error to trigger default error handling
      raise error
    end
  end
end
