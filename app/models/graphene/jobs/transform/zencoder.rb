# frozen_string_literal: true

module Jobs
  module Transform
    class Zencoder < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA_METADATA,
        Tasks::Zencoder::PrepareUrls,
        Tasks::Zencoder::CreateJob
      ]

      def process
        process_tasks(stack) do |response|
          zencoder_job_id = response.body.fetch("id")
          update!(identifier: identifier.merge(zencoder_job_id: zencoder_job_id))

          ZencoderPollJob.perform_in(
            ENV.fetch("ZENCODER_POLL_DELAY"), id, zencoder_job_id
          )

          yield(response) if block_given?
        end
      end
    end
  end
end
