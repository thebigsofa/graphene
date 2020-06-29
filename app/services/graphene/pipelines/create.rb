# frozen_string_literal: true

module Graphene
  module Pipelines
    class Create
      attr_reader :params

      def initialize(params)
        @params = HashWithIndifferentAccess.new(params)
      end

      # rubocop:disable Metrics/AbcSize
      def call(raise_error = false)
        Graphene::Pipeline.from_params_and_graph(params, graph).tap do |pipeline|
          next unless raise_error || pipeline.valid?

          ActiveRecord::Base.transaction do
            pipeline.identifier = params.dig("identifier", "value").to_s
            pipeline.identifier_type = params.dig("identifier", "type").to_s
            pipeline.audits.push(audit)
            pipeline.save!
            pipeline.reload.each(&:save!)
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      def graph
        @graph ||= Graphene::Graph::Builder.new(
          params,
          params[:jobs],
          mapping_and_priorities: params[:mappings_and_priorities]
        ).to_graph
      end

      def audit
        {
          "params" => params,
          "timestamp" => Time.zone.now
        }
      end
    end
  end
end
