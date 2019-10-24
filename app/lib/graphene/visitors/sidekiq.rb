# frozen_string_literal: true

require "sidekiq-status"

module Graphene
  module Visitors
    class Sidekiq < Visitor
      MAX_RETRIES = 5

      include ::Sidekiq::Status::Worker
      include ::Sidekiq::Worker
      include ::Graphene::Timeoutable

      sidekiq_options(backtrace: true, retry: false, dead: false)

      def perform(gid, retries = 0, reset = false)
        ActiveRecord::Base.connection_pool.release_connection
        ActiveRecord::Base.connection_pool.with_connection do
          job = GlobalID::Locator.locate(gid)
          if job.respond_to?(:process)
            process(job, retries, reset)
          else
            job.accept(self)
          end
        end
      end

      # rubocop:disable  Metrics/CyclomaticComplexity
      # rubocop:disable  Metrics/MethodLength
      # rubocop:disable  Metrics/PerceivedComplexity
      # rubocop:disable  Metrics/AbcSize
      def process(job, retries = 0, reset = false)
        job.with_lock do
          return job.accept(self) if job.complete?
          return if job.cancelled?
          return unless job.pending? || (job.retrying? && retries > 0) || reset
        end
        fail_dependent(job) && return if parents_failed?(job)
        parent_state_check(job)
      rescue ActiveRecord::StatementInvalid => e
        re_enqueue(retries, job, true)
      rescue Graphene::Tasks::Task::HaltError => e
        job.fail!(e.error)
        job.accept(self)
      rescue StandardError => e
        ActiveRecord::Base.connection_pool.with_connection do
          handle_error(job, e, retries)
        end
      rescue ActiveRecord::StaleObjectError => e
        re_enqueue(retries, job)
      end
      # rubocop:enable  Metrics/CyclomaticComplexity
      # rubocop:enable  Metrics/MethodLength
      # rubocop:enable  Metrics/PerceivedComplexity
      # rubocop:enable  Metrics/AbcSize

      def visit(job)
        self.class.set(queue: job.queue).perform_async(job.to_global_id)
        Graphene::Tracking::SidekiqTrackable.call(job.queue)
        tracker.perform_async(job.queue)
      end

      private

      def tracker
        @tracker ||= Graphene.config.sidekiq_tracker
      end

      def fail_dependent(job)
        job.fail!(Jobs::DependencyError.new("one or more parent jobs failed"))
        job.accept(self)
      end

      def re_enqueue(retries, job, reset = false)
        delay = retry_delay(retries)
        self.class.set(queue: job.queue).perform_in(
          delay, job.to_global_id, retries + 1, reset
        )
      end

      def parent_state_check(job)
        process_job(job) if parents_complete?(job)
      end

      def process_job(job)
        job.in_progress!
        tracker.perform_async(job.queue)
        with_timeout(5.hours, tracking_alert(job)) { job.process }
        job.accept(self)
      end

      def tracking_alert(job)
        { 30 => proc { tracker.perform_async(job.queue) } }
      end

      def handle_error(job, error, retries)
        if retries >= MAX_RETRIES
          fail_job(job, error)
        else
          retry_job(job, error, retries)
        end

        # Re-raise error to trigger default error handling
        raise error
      end

      def fail_job(job, error)
        ::Sidekiq.logger.info("#{job.class.name} #{job.id}: Retries exhausted")
        job.fail!(error)
        job.accept(self)
      end

      # rubocop:disable Metrics/AbcSize
      def retry_job(job, error, retries)
        job.retrying!(error) unless job.retrying?
        delay = retry_delay(retries)
        message = "#{job.class.name} #{job.id}: Retry #{retries + 1} of #{MAX_RETRIES} in #{delay} seconds"
        ::Sidekiq.logger.info(message)
        self.class.set(queue: job.queue).perform_in(delay, job.to_global_id, retries + 1)
      end
      # rubocop:enable Metrics/AbcSize

      def parents_failed?(job)
        job.parents.any? do |parent|
          parent.with_lock { parent.failed? }
        end
      end

      def parents_complete?(job)
        job.parents.empty? || job.parents.all? do |parent|
          parent.with_lock { parent.complete? }
        end
      end

      # Sidekiq's default retry function
      def retry_delay(count)
        (count**4) + 15 + (rand(30) * (count + 1))
      end
    end
  end
end
