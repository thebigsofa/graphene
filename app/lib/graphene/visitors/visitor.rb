# frozen_string_literal: true

module Graphene
  module Visitors
    class Visitor
      def visit(job)
        job.accept(self)
      end
    end
  end
end
