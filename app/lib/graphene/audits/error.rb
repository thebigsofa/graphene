# frozen_string_literal: true

module Graphene
  module Audits
    class Error < Base
      attr_reader :error, :message

      def initialize(job, error, message)
        super(job)
        @error = error
        @message = message
      end

      def to_h
        super.merge(error: error, error_message: message)
      end
    end
  end
end
