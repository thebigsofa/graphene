# frozen_string_literal: true

module Graphene
  module Graph
    class Builder
      def initialize(params, jobs, mapping_and_priorities: "default")
        @params = params.as_json
        @jobs = jobs
        @mapping = Graphene::Graph::Config.call(mapping_and_priorities).mapping
        @priorities = Graphene::Graph::Config.call(mapping_and_priorities).priorities
      end

      def to_graph
        jobs_grouped_by_priority.map do |group|
          if group.count == 1
            build_group_templates(group.first).first.first
          else
            group.sort.flat_map { |sub_group| build_group_templates(sub_group) }
          end
        end
      end

      private

      attr_reader :params, :jobs, :mapping, :priorities

      def build_group_templates(group, jobs = nil)
        (jobs || mapping.fetch(group)).map do |job|
          if job.is_a?(Array)
            build_group_templates(group, job)
          else
            Graphene::Graph::JobTemplate.new(
              job, group: group, parent_jobs: params.dig(group, "parents")
            )
          end
        end
      end

      def jobs_grouped_by_priority
        Hash[jobs.group_by { |p| priorities.fetch(p) }.sort].values
      end
    end
  end
end
