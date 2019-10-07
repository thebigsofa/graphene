# frozen_string_literal: true

class PipelinesController < AuthenticatedController
  def create
    if (@pipeline = CreatePipeline.new(pipeline_params).call).persisted?
      SidekiqVisitor.new.visit(pipeline)
      render(status: :created, json: pipeline_to_json)
    else
      render(status: :unprocessable_entity, json: { errors: pipeline.errors }.to_json)
    end
  end

  def show
    render(json: pipeline_to_json)
  end

  def update
    if UpdatePipeline.new(pipeline, pipeline_params).call
      render(json: pipeline_to_json)
    else
      render(status: :unprocessable_entity, json: { errors: pipeline.errors }.to_json)
    end
  end

  def locked
    render(
      json: {
        pipeline_id: pipeline.id,
        is_locked: LockedPipeline.new(pipeline).call
      }
    )
  end

  def cancel
    if CancelPipeline.new(pipeline).call
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
    @pipeline ||= Pipeline.find(params[:id])
  end

  def pipeline_to_json
    PipelineSerializer.new(pipeline.reload).to_json
  end
end
