# frozen_string_literal: true

module Graphene
  module Pipelines
    class Create
      attr_reader :params

      def initialize(params)
        @params = HashWithIndifferentAccess.new(params)
      end

      def call(raise_error = false)
        Graphene::Pipeline.from_params_and_graph(params, graph).tap do |pipeline|
          next unless raise_error || pipeline.valid?

          ActiveRecord::Base.transaction do
            pipeline.audits.push(audit)
            pipeline.save!
            pipeline.each(&:save!)
          end
        end
      end

      private

      def graph
        @graph ||= Graphene::Graph::Builder.new(
          params[:jobs],
          mapping: mappings_and_priorities["mapping"],
          priorities: mappings_and_priorities["priorities"]
        ).to_graph
      end

      def mappings_and_priorities
        Graphene.config.mappings_and_priorities.fetch(
          params[:mappings_and_priorities] || "default"
        )
      rescue KeyError
        raise "No `#{params[:mappings_and_priorities]}` mappings_and_priorities configuration"
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