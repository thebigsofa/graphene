# frozen_string_literal: true

module Graphene
  class UpdatePipeline
    attr_reader :pipeline, :params

    FINAL_STATES = %w[complete failed].freeze

    def initialize(pipeline, params)
      @pipeline = pipeline
      @params = params.to_h
    end

    def call
      return false unless pipeline_updated?

      enqueue_sidekiq_visitor!
      true
    end

    private

    def pipeline_updated?
      ActiveRecord::Base.transaction do
        check_job_states!
        update_graph_version!
        update_jobs!
        update_pipeline!
      end
    end

    def check_job_states!
      return unless pipeline_locked?

      pipeline.errors.add(:params, message: "pipeline is locked")
      raise ActiveRecord::Rollback, "jobs in progress"
    end

    def update_graph_version!
      return unless changed_params.include?(:jobs)

      pipeline.increment_version_and_add_graph(
        Graph::Builder.new(params.fetch(:jobs)).to_graph
      )
    end

    def update_jobs!
      pipeline.each do |job|
        next unless job_params_changed?(job)

        job.assign_attributes(state: :pending, error: nil, error_message: nil)
        CheckStateVisitor.new.visit(job)
      end
      pipeline.each(&:save!)
    end

    def update_pipeline!
      pipeline_params = pipeline.params.deep_symbolize_keys.deep_merge(
        params.deep_symbolize_keys
      )

      pipeline.update(params: pipeline_params, audits: audit).tap do |success|
        raise ActiveRecord::Rollback, "validation failed" unless success
      end
    end

    def audit
      pipeline.audits.push(
        "params" => params,
        "timestamp" => Time.zone.now
      )
    end

    def enqueue_sidekiq_visitor!
      return unless changed_params.include?(:jobs) ||
                    pipeline.jobs.any? { |job| job_params_changed?(job) }

      SidekiqVisitor.new.visit(pipeline)
    end

    def job_params_changed?(job)
      changed_job_params? || changed_params.include?(job.group.to_sym)
    end

    def changed_job_params?
      params["jobs"].present? && (params["jobs"].count < pipeline.params["jobs"].count)
    end

    def changed_params
      @changed_params ||= diff_params(pipeline.params, params)
    end

    def pipeline_locked?
      (pipeline.jobs.pluck(:state).uniq - FINAL_STATES).any?
    end

    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Metrics/AbcSize
    def diff_params(a, b)
      a = HashWithIndifferentAccess.new(a)
      b = HashWithIndifferentAccess.new(b)

      (a.keys + b.keys).map(&:to_sym).uniq.each_with_object([]) do |key, diff|
        diff << key if !a[key].blank? && !b[key].blank? && a[key] != b[key]
      end
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName
    # rubocop:enable Metrics/AbcSize
  end
end
