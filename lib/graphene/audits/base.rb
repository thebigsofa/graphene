# frozen_string_literal: true

module Graphene
  module Audits
    class Base
      attr_reader :job

      def initialize(job)
        @job = job
      end

      def to_h
        {
          version: job.version,
          type: self.class.name.demodulize.underscore,
          timestamp: Time.now
        }
      end

      def as_json(*args)
        to_h.as_json(*args)
      end
    end
  end
end
