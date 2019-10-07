# frozen_string_literal: true

module Jobs
  module QA
    class DurationFilter < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA_METADATA,
        Tasks::Filters::MediaDurationFilter
      ]
    end
  end
end
