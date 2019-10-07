# frozen_string_literal: true

module Jobs
  module Transform
    class SkipEncode < Jobs::Base
      STACK = Stack[
        Tasks::DOWNLOAD_ORIGINAL_MEDIA,
        Tasks::MediaInfo::ValidateSourceMp4,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]
    end
  end
end
