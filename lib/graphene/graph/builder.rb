# frozen_string_literal: true

module Graphene
  module Graph
    class Builder
      def initialize(jobs, mapping:, priorities:)
        @jobs = jobs
        @mapping = mapping
        @priorities = priorities
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

      attr_reader :jobs, :mapping, :priorities

      def build_group_templates(group, jobs = nil)
        (jobs || mapping.fetch(group)).map do |job|
          if job.is_a?(Array)
            build_group_templates(group, job)
          else
            JobTemplate.new(job, group)
          end
        end
      end

      def jobs_grouped_by_priority
        Hash[jobs.group_by { |p| priorities.fetch(p) }.sort].values
      end
    end
  end
end
