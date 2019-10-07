# frozen_string_literal: true

class Visitor
  def visit(job)
    job.accept(self)
  end
end
