# frozen_string_literal: true

module Graphene
  class PipelineSerializer
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def to_json(*args)
      {
        id: pipeline.id,
        params: pipeline.params,
        jobs: jobs,
        version: pipeline.version,
        timestamp: Time.now,
        state: state_for_jobs(pipeline.jobs),
        audits: pipeline.audits
      }.to_json(*args)
    end

    private

    # rubocop:disable Metrics/MethodLength
    def jobs
      pipeline.group_by(&:group).each_with_object({}) do |(group, jobs), result|
        result[group] = {
          version: version_for_job(group, jobs),
          state: state_for_jobs(jobs),
          errors: errors_for_jobs(jobs),
          children: children_for_jobs(group, jobs),
          parents: parents_for_jobs(group, jobs),
          audits: audits_for_jobs(jobs),
          artifacts: artifacts_for_jobs(jobs)
        }
      end
    end
    # rubocop:enable Metrics/MethodLength

    def artifacts_for_jobs(jobs)
      jobs.map(&:artifacts).reduce do |artifact, job|
        artifact.merge(job) { |_key, *values| values.reduce(:merge) }
      end
    end

    def audits_for_jobs(jobs)
      all = jobs.inject([]) do |audits, job|
        audits + audits_for_job(job)
      end

      all.sort_by do |audit|
        audit.fetch("timestamp")
      end
    end

    def audits_for_job(job)
      job.audits.map do |audit|
        audit.dup.merge(
          "timestamp" => Time.parse(audit.fetch("timestamp")),
          "job_id" => job.id,
          "job" => job.class.name
        )
      end
    end

    def children_for_jobs(group, jobs)
      jobs.map(&:children).flatten.map(&:group).uniq.reject do |child_group|
        child_group == group
      end
    end

    def parents_for_jobs(group, jobs)
      jobs.map(&:parents).flatten.map(&:group).uniq.reject do |child_group|
        child_group == group
      end
    end

    def version_for_job(group, jobs)
      jobs.find { |job| job.group == group }.version
    end

    def errors_for_jobs(jobs)
      jobs.each_with_object([]) do |job, errors|
        next unless job.failed?

        errors << { error: job.error, error_message: job.error_message }
      end
    end

    # rubocop:disable  Metrics/CyclomaticComplexity
    def state_for_jobs(jobs)
      return "in_progress" if jobs.any?(&:in_progress?)
      return "retrying" if jobs.any?(&:retrying?)
      return "pending" if jobs.any?(&:pending?)
      return "failed" if jobs.any?(&:failed?)
      return "cancelled" if jobs.any?(&:cancelled?)
      return "complete" if jobs.all?(&:complete?)

      raise "invalid state"
    end
    # rubocop:enable  Metrics/CyclomaticComplexity
  end
end
