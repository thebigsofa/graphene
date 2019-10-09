# frozen_string_literal: true

module Graphene
  class CallbackNotifierJob
    include Sidekiq::Worker
    require_relative "../lib/big_sofa/auth_middleware"
    FARRADAY_ERRORS = [::Faraday::ResourceNotFound, ::Faraday::TimeoutError].freeze

    sidekiq_options(queue: :pipeline_poll, backtrace: true, retry: false)

    MAX_RETRIES = 5

    def perform(pipeline_id, callback, retries = 0)
      return if Graphene::CallbackAggregate.count_for(pipeline_id) < 1

      Graphene::CallbackAggregate.clear(pipeline_id)

      pipeline = Pipeline.find(pipeline_id)
      url = callback.fetch("url")
      connection(url, callback).post(URI(url).path) do |req|
        req.body = PipelineSerializer.new(pipeline)
        req.headers.merge!(callback.fetch("headers", {}))
      end
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

    def connection(url, callback)
      Faraday.new(url: URI.join(url, "/").to_s) do |faraday|
        faraday.response(:raise_error)
        faraday.response(:json)
        faraday.request(:json)
        if callback["big_sofa_auth"]
          faraday.request(:big_sofa_auth, ENV["LOCATION"], ENV["LOCATION_SECRET"])
        end
        faraday.adapter(:excon)
      end
    end
  end
end
