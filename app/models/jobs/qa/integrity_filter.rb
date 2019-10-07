# frozen_string_literal: true

module Jobs
  module QA
    class IntegrityFilter < Jobs::Base
      STACK = Stack[
        Tasks::Platform::GetOriginalMediaURL,
        Tasks::DOWNLOAD_FILE,
        Tasks::MediaInfo::ReadMetadata,
        Tasks::Filters::TruncationFilter,
        Tasks::Filters::TrackCountFilter
      ]

      def queue
        :pipeline_gpu
      end
    end
  end
end
