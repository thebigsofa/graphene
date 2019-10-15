# frozen_string_literal: true
module Graphene
  module Jobs
    class DependencyError < StandardError; end

    # rubocop:disable Metrics/ClassLength
    class Base < ApplicationRecord
      class WithLogging
        attr_reader :task, :job

        def initialize(job, task)
          @job = job
          @task = task
        end

        def call(*args, &block)
          Sidekiq.logger.info("pipeline: #{job.pipeline_id} job: #{job.class.name} #{job.id} " \
                              "running task: #{task.class.name}")
          task.call(*args, &block)
        end
      end

      STACK = ::Sheaf::Stack.new

      include Enumerable
      include Concerns::Stateable
      include Sheaf

      has_many :child_edges,
               class_name: "Edge",
               foreign_key: :origin_id,
               dependent: :destroy,
               inverse_of: :origin

      has_many :children,
               through: :child_edges,
               source: :destination

      has_many :parent_edges,
               class_name: "Edge",
               foreign_key: :destination_id,
               dependent: :destroy,
               inverse_of: :destination

      has_many :parents,
               through: :parent_edges,
               source: :origin

      belongs_to :pipeline, touch: true, class_name: "Graphene::Pipeline"

      scope :version, ->(version) { where(version: version) }

      scope :without_parents, lambda {
        joins("LEFT JOIN edges ON edges.destination_id = jobs.id")
          .where("edges.destination_id IS NULL")
      }

      scope :with_artifacts, lambda { |artifacts|
        where("artifacts @> ?", artifacts.is_a?(String) ? artifacts : artifacts.to_json)
      }

      scope :with_identifier, lambda { |identifier|
        where("identifier @> ?", identifier.is_a?(String) ? identifier : identifier.to_json)
      }

      validate :validate_audits_type
      validates :group, presence: true

      before_validation :set_default_group
      before_update :audit_state_changes
      before_update :audit_errors

      self.table_name = "jobs"

      def self.from_graph(graph, pipeline:, children: [])
        graph.reverse.inject(children) do |memo, job|
          if job.is_a?(Array)
            job.map do |edge|
              from_graph(edge, children: memo, pipeline: pipeline).first
            end
          else
            [job.new(children: memo, pipeline: pipeline, version: pipeline.version)]
          end
        end
      end

      define_state :pending
      define_state :complete
      define_state :in_progress
      define_state :cancelled, trigger_name: :cancel!
      define_state :retrying do |error|
        { error: error.class.name, error_message: error.message }
      end

      define_state :failed, trigger_name: :fail! do |error|
        { error: error.class.name, error_message: error.message }
      end

      def each(&block)
        Graphene::Visitors::Each.new(block).visit(self)
      end

      def accept(visitor)
        children.each { |child| visitor.visit(child) }
      end

      def process(stack = self.stack, *params, &block)
        process_tasks(stack, *params, &block)
        complete! unless pipeline.jobs.any?(&:cancelled?)
      end

      def process_tasks(stack = self.stack, *params, &block)
        stack.fmap do |klass|
          task = klass.new(pipeline.params.fetch(group, {}).deep_dup).tap do |t|
            t.params[:current_job] = self
            t.logger = Graphene::Tasks::Logger.new(self)
          end
          WithLogging.new(self, task)
        end.call(*params, &block)
      end

      def stack
        self.class::STACK
      end

      def json_schema_properties
        {
          group.to_sym => {
            type: :object,
            properties: stack.inject({}) do |properties, task|
              properties.merge(task.json_schema_properties)
            end,
            required: stack.flat_map(&:required_params).uniq
          }
        }
      end

      def queue
        :pipeline
      end

      private

      def set_default_group
        self.group ||= self.class.name.demodulize.underscore
      end

      def audit_state_changes
        return unless state_changed?

        audits << Graphene::Audits::StateChange.new(self, *changes.fetch(:state))
      end

      def audit_errors
        return unless error_changed? && error

        audits << Graphene::Audits::Error.new(self, error, error_message)
      end

      def validate_audits_type
        errors.add(:audits, "incorrect type") unless audits.is_a?(Array)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
