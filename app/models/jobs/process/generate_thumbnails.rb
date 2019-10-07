# frozen_string_literal: true

module Jobs
  module Process
    class GenerateThumbnails < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::FFMPEG::NormalizeMediaFormat,
        Tasks::FFMPEG::ExtractThumbnail,
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
