# frozen_string_literal: true

module Graphene
  module CallbackHandlers
    class Kafka
      attr_reader :pipeline, :callback

      def initialize(pipeline:, callback:)
        @pipeline = pipeline
        @callback = callback.with_indifferent_access
      end

      def self.call(pipeline:, callback:)
        new(pipeline: pipeline, callback: callback).call
      end

      def call
        kafka.deliver_message(json_payload, topic: topic)
      end

      private

      def topic
        callback.fetch(:topic, default_topic)
      end

      def client
        @client ||= Kafka.new(cluster, client_id: client_id)
      end

      def json_payload
        @json_payload ||= JSON.dump(Graphene::Serializers::PipelineSerializer.new(pipeline))
      end

      def cluster
        @cluster ||= Graphene.config.callback_auth[:kafka_clusters]
      end

      def client_id
        @client_id ||= Graphene.config.callback_auth[:client_id]
      end

      def default_topic
        @default_topic ||= Graphene.config.callback_auth[:topic]
      end
    end
  end
end
