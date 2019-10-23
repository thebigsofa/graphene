# frozen_string_literal: true

module Graphene
  module Tasks
    class Logger
      include Concerns::Loggable

      attr_reader :job, :logger

      def initialize(job, logger = default_logger)
        @job = job
        @logger = logger
      end

      def log_prefix_elements
        {
          pipeline: job.pipeline_id,
          job: [job.class.name, job.id]
        }
      end

      on_log do |message, level|
        audit_message(level, message)
        message
      end

      private

      def default_logger
        Sidekiq.server? ? Sidekiq.logger : Rails.logger
      end

      def audit_message(level, message)
        job.audits << Graphene::Audits::Log.new(job, level, message)
      end
    end
  end
end
