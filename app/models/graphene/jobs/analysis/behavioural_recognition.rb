# frozen_string_literal: true

module Jobs
  module Analysis
    class BehaviouralRecognition < Jobs::Base
      STACK = Stack[
        Tasks::Detection::BehaviouralRecognition
      ]

      def process
        process_tasks(stack) do |response|
          update!(
            identifier: identifier.merge(behavioural_recognition_video_id: response)
          )

          StreamingoPollJob.perform_in(1.minute, id)

          yield(response) if block_given?
        end
      end
    end
  end
end
