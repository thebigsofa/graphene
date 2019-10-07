# frozen_string_literal: true

module Jobs
  module QA
    class AdultContentFilter < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::FFMPEG::NormalizeMediaFormat,
        Tasks::FFMPEG::ExtractFrames,
        Tasks::GoogleVision::Request::AdultContentDetection,
        Tasks::GoogleVision::AdultContentFilter,
        Tasks::Helpers::ZipUp,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]

      def process(&block)
        super(STACK, &block)
      end

      def queue
        :pipeline_gpu
      end
    end
  end
end
