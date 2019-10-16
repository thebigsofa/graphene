# frozen_string_literal: true

module Graphene
  class Visitor
    def visit(job)
      job.accept(self)
    end
  end
end
