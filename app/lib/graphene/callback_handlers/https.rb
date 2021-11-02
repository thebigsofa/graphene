# frozen_string_literal: true

module Graphene
  module CallbackHandlers
    class Https
      attr_reader :pipeline, :callback

      def initialize(pipeline:, callback:)
        @pipeline = pipeline
        @callback = callback
      end

      def self.call(pipeline:, callback:)
        new(pipeline: pipeline, callback: callback).call
      end

      def call
        connection(url, callback).post(URI(url).path) do |req|
          req.body = Graphene::Serializers::PipelineSerializer.new(pipeline)
          req.headers.merge!(callback.fetch("headers", {}))
        end
      end

      private

      def url
        @url ||= callback.fetch("url")
      end

      def connection(url, callback)
        Graphene::Connection.get(URI.join(url, "/").to_s, callback.with_indifferent_access)
      end
    end
  end

  module Connection
    class << self
      def get(url, callback)
        Faraday.new(url: url) do |faraday|
          faraday.response(:raise_error)
          faraday.response(:json)
          faraday.request(:json)

          auth = OpenStruct.new(Graphene.config.callback_auth)
          faraday.request(auth.name, *auth.credentials) if callback[auth.name]

          faraday.adapter(:excon)
        end
      end
    end
  end
end
