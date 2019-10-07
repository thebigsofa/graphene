# frozen_string_literal: true

module Jobs
  module Process
    class GenerateImageThumbnails < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::FFMPEG::Rotate,
        Tasks::Minimagick::Watermark,
        Tasks::Minimagick::GenerateThumbnailVersions,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]

      def queue
        :pipeline_gpu
      end
    end
  end
end
