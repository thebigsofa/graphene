# frozen_string_literal: true

module Graphene
  class PipelinesController < ApplicationController
    def create
      if (@pipeline = Graphene::Pipelines::Create.new(pipeline_params).call).persisted?
        Graphene::Visitors::Sidekiq.new.visit(pipeline)
        render(status: :created, json: pipeline_to_json)
      else
        render(status: :unprocessable_entity, json: { errors: pipeline.errors }.to_json)
      end
    end

    def show
      render(json: pipeline_to_json)
    end

    def update
      if Graphene::Pipelines::Update.new(pipeline, pipeline_params).call
        render(json: pipeline_to_json)
      else
        render(status: :unprocessable_entity, json: { errors: pipeline.errors }.to_json)
      end
    end

    def locked
      render(
        json: {
          pipeline_id: pipeline.id,
          is_locked: Graphene::Pipelines::Locked.new(pipeline).call
        }
      )
    end

    def cancel
      if Graphene::Pipelines::Cancel.new(pipeline).call
        render(json: pipeline_to_json)
      else
        render(status: :unprocessable_entity, json: { errors: pipeline.errors }.to_json)
      end
    end

    private

    def pipeline_params
      params.except(:controller, :action, :pipeline, :id).permit!
    end

    def pipeline
      @pipeline ||= Graphene::Pipeline.find(params[:id])
    end

    def pipeline_to_json
      Graphene::PipelineSerializer.new(pipeline.reload).to_json
    end
  end
end
