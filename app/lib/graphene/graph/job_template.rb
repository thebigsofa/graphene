# frozen_string_literal: true

module Graphene
  module Graph
    class JobTemplate < SimpleDelegator
      attr_reader :group, :parent_job

      def initialize(job, group: nil, parent_job: nil)
        __setobj__(job)
        @group = group
        @parent_job = parent_job
      end

      def new(attrs = {}, &block)
        __getobj__.new({ group: group, parent_job: parent_job }.merge(attrs), &block)
      end
    end
  end
end
