# frozen_string_literal: true

class Prune
  class << self
    include Concerns::Loggable

    on_log do |message|
      "#{self.class.name} #{message}"
    end

    def call
      old_jobs.each do |job|
        debug("Failing job: #{job.id} because it has timed out")
        job.fail!(Timeoutable::PollTimeoutError.new("Job has timed out"))
        job.accept(SidekiqVisitor.new)
      end
    end

    def old_jobs
      Jobs::Base.where(state: "in_progress").where("state_changed_at < ?", 2.5.days.ago)
    end
  end
end
