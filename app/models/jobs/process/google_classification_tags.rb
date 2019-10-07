# frozen_string_literal: true

module Jobs
  module Process
    class GoogleClassificationTags < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::FFMPEG::NormalizeMediaFormat,
        Tasks::FFMPEG::ExtractFrames,
        Tasks::GoogleVision::Request::Classification,
        Tasks::GoogleVision::AggregateResponses
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
