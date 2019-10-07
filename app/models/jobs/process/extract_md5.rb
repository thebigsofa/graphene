# frozen_string_literal: true

module Jobs
  module Process
    class ExtractMD5 < Jobs::Base
      STACK = Stack[
        Tasks::Platform::GetOriginalMediaURL,
        Tasks::Readers::HTTPDownloadReader,
        Tasks::Writers::MD5Writer,
        Tasks::Platform::UpdateMediaMD5
      ]

      def queue
        :pipeline_gpu
      end
    end
  end
end
