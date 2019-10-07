# frozen_string_literal: true

module Jobs
  module Analysis
    class PeopleDetection < Jobs::Base
      STACK = Stack[
        Tasks::Detection::People
      ]

      def process
        process_tasks(stack) do |response|
          response = JSON.parse(response.body)

          update!(
            identifier: identifier.merge(people_detection_job_id: response["job_id"])
          )

          yield(response) if block_given?
        end
      end
    end
  end
end
