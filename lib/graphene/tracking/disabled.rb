# frozen_string_literal: true

module Graphene
  module Tracking
    class Disabled
      def perform(_)
        ::Sidekiq.logger.info("Sidekiq tracking is disabled. Implement your own... bitch.")
      end
    end
  end
end
