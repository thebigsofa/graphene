# frozen_string_literal: true

module Jobs
  module Analysis
    class NaturalLanguageAnalysis < Jobs::Base
      STACK = Stack[
        Tasks::Helpers::WithTranscript,
        Tasks::Helpers::HttpGet,
        Tasks::Detection::WatsonRequest,
        Tasks::Detection::SherlockRequest,
        Tasks::Detection::WatsonParser,
        Tasks::SAVE_AS_JSON,
        Tasks::Helpers::WithCallback,
        Tasks::UPLOAD_FILES
      ]
    end
  end
end
