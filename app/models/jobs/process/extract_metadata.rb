# frozen_string_literal: true

module Jobs
  module Process
    class ExtractMetadata < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA_METADATA,
        Tasks::Platform::SerializeMetadata,
        Tasks::Platform::UpdateMediaMetadata,
        Tasks::SAVE_AS_JSON,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]

      def queue
        :pipeline_gpu
      end
    end
  end
end
