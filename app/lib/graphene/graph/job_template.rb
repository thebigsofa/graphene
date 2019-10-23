# frozen_string_literal: true

module Graphene
  module Graph
    class JobTemplate < SimpleDelegator
      attr_reader :group

      def initialize(job, group = nil)
        __setobj__(job)
        @group = group
      end

      def new(attrs = {}, &block)
        __getobj__.new({ group: group }.merge(attrs), &block)
      end
    end
  end
end
