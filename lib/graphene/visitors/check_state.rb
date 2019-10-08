# frozen_string_literal: true

# Traverses a (sub-)graph and resets job states to `pending` based unless all
# parent states are final states (eg. `failed` or `complete`).
module Graphene
  module Visitors
    class CheckState < Visitor
      FINAL_STATES = Set.new(%i[complete failed]).freeze

      attr_reader :stack

      def initialize
        @stack = []
      end

      def visit(job)
        if stack.last.respond_to?(:state) && !FINAL_STATES.include?(stack.last.state)
          job.state = :pending
        end

        stack.push(job)
        super
        stack.pop
      end
    end
  end
end
