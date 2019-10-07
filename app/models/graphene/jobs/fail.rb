# frozen_string_literal: true

module Jobs
  class Fail < Jobs::Base
    STACK = Stack[Tasks::Helpers::Fail]
  end
end
