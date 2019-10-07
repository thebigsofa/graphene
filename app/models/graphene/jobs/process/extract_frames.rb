# frozen_string_literal: true

module Jobs
  module Process
    class ExtractFrames < Jobs::Base
      STACK = Stack[
        Tasks::Helpers::WithSource,
        Tasks::DOWNLOAD_FILE,
        Tasks::FFMPEG::ExtractFrames,
        Tasks::Helpers::ZipUp,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]

      def queue
        :pipeline_gpu
      end
    end
  end
end
