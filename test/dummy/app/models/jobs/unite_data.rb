# frozen_string_literal: true

module Jobs
  module Tasks
    class UniteData
      include Graphene::Tasks::Task

      def initialize(data:)
        super
      end

      def call
        yield("-#{data[:simple]}|#{data[:smooth]}-")
      end
    end
  end

  class UniteData < Graphene::Jobs::Base
    STACK = Graphene::Stack[
      Jobs::Tasks::UniteData
    ]
  end
end
