# frozen_string_literal: true

module Support
  module Jobs
    class DoNothing < Graphene::Jobs::Base
      def process
        # Do nothing
      end
    end
  end
end
