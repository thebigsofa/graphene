# frozen_string_literal: true

module Graphene
  class LockedPipeline
    FINAL_STATES = %w[complete failed].freeze

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def call
      pipeline_locked?
    end

    private

    attr_reader :pipeline

    def pipeline_locked?
      (pipeline.jobs.pluck(:state).uniq - FINAL_STATES).any?
    end
  end
end
