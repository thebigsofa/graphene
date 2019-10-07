# frozen_string_literal: true

module Jobs
  module QA
    class BlacklistFilter < Jobs::Base
      STACK = Stack[
      Tasks::Platform::GetOriginalMediaURL,
      Tasks::Readers::HTTPDownloadReader,
      Tasks::Writers::MD5Writer,
      Tasks::Filters::BlacklistedMediaFilter
      ]

      def process(&block)
        super(STACK, &block)
      end
    end
  end
end
