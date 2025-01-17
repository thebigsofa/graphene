# frozen_string_literal: true

module Graphene
  # rubocop:disable Metrics/ClassLength
  class Pipeline < ApplicationRecord
    DEFAULT_PARAMS_JSON_SCHEMA = {
      type: "object",
      properties: {
        jobs: {
          type: "array",
          items: {
            type: "string"
          }
        }
      },
      required: %w[jobs]
    }.freeze

    include ::Enumerable
    include ::PgSearch::Model

    multisearchable against: %i[id params]
    pg_search_scope :search, against: %i[id identifier]

    has_many :jobs, ->(pipeline) { version(pipeline.version) }, class_name: "Graphene::Jobs::Base"
    has_many :all_jobs, class_name: "Graphene::Jobs::Base", dependent: :destroy

    has_many :children, ->(pipeline) { version(pipeline.version).without_parents }, class_name: "Graphene::Jobs::Base"

    validates(
      :params,
      presence: true,
      json: {
        schema: :params_json_schema,
        message: ->(errors) { errors }
      }
    )

    after_commit :notify_callbacks!, only: [:update]

    def self.from_params_and_graph(params, graph)
      new(params: params).tap do |pipeline|
        pipeline.add_graph(graph)
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def add_graph(graph)
      result = Graphene::Jobs::Base.from_graph(graph, pipeline: self).tap do |roots|
        children.reset if persisted? && children.loaded?
        jobs.reset if persisted? && jobs.loaded?
        add_roots_without_save(roots)
      end

      leaf_jobs = jobs.select { |jj| jj.parent_jobs.present? }.uniq.compact
      if leaf_jobs.any?
        parent_groups = leaf_jobs.map(&:parent_jobs).flatten.uniq
        jobs.select { |jj| parent_groups.include?(jj.group) }.map do |jj|
          jj.children = []
        end

        leaf_jobs.map do |jobbie|
          jobbie.parents = jobs.select { |jj| jobbie.parent_jobs.include?(jj.group) }
        end
      end

      result
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    def increment_version_and_add_graph(graph)
      # Create mapping from job class to jobs
      previous_jobs_by_class = jobs.to_a.map { |j| [j.class, j] }.to_h
      previous_jobs_by_group = jobs.to_a.map { |j| [j.group, j] }.to_h

      # Reset associations here to evict jobs with the previous version from the cache
      children.reset
      jobs.reset
      self.version += 1
      add_graph(graph)
      match_job_attributes(previous_jobs_by_class, previous_jobs_by_group)
    end
    # rubocop:enable Metrics/AbcSize

    def accept(visitor)
      children.each { |child| visitor.visit(child) }
    end

    def each(&block)
      visitor = Graphene::Visitors::Each.new(block)
      children.each do |child|
        visitor.visit(child)
      end
    end

    def to_dot
      visitor = Graphene::Visitors::Dot.new
      visitor.visit(self)
      visitor.to_dot
    end

    def update_params!(params)
      update!(params: params)
    end

    def aggregate_callback
      if callback_aggregate.exists?
        callback_aggregate.increment
      else
        CallbackAggregate.create(pipeline_id: id, count: 1)
      end
    end

    def queue
      :pipeline
    end

    private

    def match_job_attributes(previous_jobs_by_class, previous_jobs_by_group)
      jobs.each do |job|
        source = job.group.nil? ? previous_jobs_by_class[job.class] : previous_jobs_by_group[job.group] # rubocop:disable Metrics/LineLength

        next unless source

        excluded_attributes = %w[id type version created_at updated_at]
        attrs = source.attributes.except(*excluded_attributes)

        job.assign_attributes(attrs)
      end
    end

    def add_roots_without_save(*roots)
      roots.flatten.each do |root|
        association(:children).add_to_target(root)
        root.each { |job| association(:jobs).add_to_target(job) }
      end
    end

    def params_json_schema
      DEFAULT_PARAMS_JSON_SCHEMA.deep_dup.tap do |schema|
        properties = inject({}) do |memo, job|
          memo.deep_merge(job.json_schema_properties)
        end
        schema[:properties].deep_merge!(properties)
        schema[:required].concat(params.fetch("jobs", []))
        schema[:required].uniq!
      end
    end

    def callback_aggregate
      @callback_aggregate ||= CallbackAggregate.new(pipeline_id: id)
    end

    def notify_callbacks!
      delay = Graphene.config.callback_delay.seconds
      params["callbacks"]&.each do |callback|
        aggregate_callback
        CallbackNotifierJob.perform_in(delay, id, callback.to_h)
        Graphene::Tracking::SidekiqTrackable.call(:pipeline_poll)
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
