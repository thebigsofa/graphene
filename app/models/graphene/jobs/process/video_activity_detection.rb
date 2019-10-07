# frozen_string_literal: true

module Jobs
  module Process
    class VideoActivityDetection < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::FFMPEG::VideoActivityDetection,
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
