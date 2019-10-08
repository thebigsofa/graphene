# frozen_string_literal: true

module Graphene
  module Timeoutable
    class Error < StandardError; end
    class PollTimeoutError < StandardError; end

    module_function

    def with_timeout(timeout, alerts = {})
      return yield if timeout.nil? || timeout == 0

      children = ThreadGroup.new

      spawn_timeout_alerts(alerts).each { |thread| children.add(thread) }
      children.add(spawn_timeout_timer(timeout))

      begin
        yield
      ensure
        children.list.each(&:kill)
        children.list.each(&:join)
      end
    end

    def with_poll_timeout(job)
      job.with_lock do
        return unless job.in_progress?

        if (Time.now.utc - job.state_changed_at) > ENV.fetch("POLLING_TIMEOUT").to_i
          job.fail!(PollTimeoutError.new("Job has timed out"))
        else
          yield
        end
      end
    end

    def spawn_timeout_alerts(alerts)
      alerts.map do |alert_timeout, handler|
        Thread.start do
          loop do
            sleep(alert_timeout)
            handler.call
          end
        rescue StandardError => e
          parent.raise e
        end
      end
    end

    def spawn_timeout_timer(timeout)
      parent = Thread.current
      Thread.start do
        sleep(timeout)
      rescue StandardError => e
        parent.raise e
      else
        parent.raise Error, "Timeout after #{timeout} seconds"
      end
    end
  end
end
