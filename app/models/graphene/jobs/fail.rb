# frozen_string_literal: true

module Graphene
  module Jobs
    class Fail < Graphene::Jobs::Base
      STACK = Graphene::Stack[Graphene::Tasks::Helpers::Fail]
    end
  end
end
