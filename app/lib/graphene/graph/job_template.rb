# frozen_string_literal: true

module Graphene
  module Graph
    class JobTemplate < SimpleDelegator
      attr_reader :group, :parent_jobs

      def initialize(job, group: nil, parent_jobs: nil)
        __setobj__(job)
        @group = group
        @parent_jobs = parent_jobs
      end

      def new(attrs = {}, &block)
        __getobj__.new({ group: group, parent_jobs: parent_jobs }.merge(attrs), &block)
      end
    end
  end
end
