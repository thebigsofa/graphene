module Jobs
  module Tasks
    class Smooth
      include Graphene::Tasks::Task

      def initialize(data:)
        super
      end

      def call
        yield(data[:smooth])
      end
    end
  end

  class Smooth < Graphene::Jobs::Base
    STACK = Graphene::Stack[
      Jobs::Tasks::Smooth
    ]
  end
end
