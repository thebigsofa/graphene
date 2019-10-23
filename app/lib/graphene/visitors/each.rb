# frozen_string_literal: true

module Graphene
  module Visitors
    class Each < Visitor
      attr_reader :block, :seen

      def initialize(block)
        @seen = Set.new
        @block = block
      end

      def visit(job)
        id = job.persisted? ? job.id : job.object_id
        return if seen.include?(id)

        seen.add(id)
        block.call(job)
        super
      end
    end
  end
end
