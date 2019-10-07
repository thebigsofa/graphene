# frozen_string_literal: true

module Jobs
  module QA
    class DuplicateFilter < Jobs::Base
      STACK = Stack[
        Tasks::Platform::GetOriginalMediaURL,
        Tasks::Readers::HTTPDownloadReader,
        Tasks::Writers::MD5Writer,
        Tasks::Filters::ProjectMediaMD5Filter
      ]
    end
  end
end
