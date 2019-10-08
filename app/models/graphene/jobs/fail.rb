# frozen_string_literal: true

module Graphene
  module Jobs
    class Fail < Graphene::Jobs::Base
      STACK = Stack[Graphene::Tasks::Helpers::Fail]
    end
  end
end
