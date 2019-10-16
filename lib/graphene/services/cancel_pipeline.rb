# frozen_string_literal: true

module Graphene
  class CancelPipeline
    attr_reader :pipeline

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def call
      return false unless pipeline_updated?

      true
    end

    private

    def pipeline_updated?
      ActiveRecord::Base.transaction do
        pipeline.jobs.each(&:cancel!)
      end
    end
  end
end
