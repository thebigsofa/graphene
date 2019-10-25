# frozen_string_literal: true

module Jobs
  module Transform
    module Tasks
      class WithSource
        include Graphene::Tasks::Task

        def initialize(source:)
          super
        end

        def call
          yield(source[:url], source[:filename])
        end
      end
    end

    class Zencoder < Graphene::Jobs::Base
      STACK = Graphene::Stack[
        Jobs::Transform::Tasks::WithSource
      ]

      def process
        process_tasks(stack) do |response|
          update!(identifier: identifier.merge(zencoder_job_id: SecureRandom.uuid))

          yield("Encoding #{response} complete.") if block_given?
        end
      end
    end
  end
end
