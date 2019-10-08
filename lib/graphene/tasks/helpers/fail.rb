# frozen_string_literal: true

module Graphene
  module Tasks
    module Helpers
      class Fail
        class Error < StandardError; end

        include Task

        def call(*_args)
          error("failing")
          halt!(Error, "forced failure")
        end
      end
    end
  end
end
