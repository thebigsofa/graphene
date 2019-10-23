# frozen_string_literal: true

module Jobs
  module Tasks
    class Simple
      include Graphene::Tasks::Task

      def initialize(data:)
        super
      end

      def call
        yield(data[:simple])
      end
    end
  end

  class Simple < Graphene::Jobs::Base
    STACK = Graphene::Stack[
      Jobs::Tasks::Simple
    ]
  end
end
