# frozen_string_literal: true

class CreatePipeline
  attr_reader :params

  def initialize(params)
    @params = HashWithIndifferentAccess.new(params)
  end

  def call(raise_error = false)
    Pipeline.from_params_and_graph(params, graph).tap do |pipeline|
      next unless raise_error || pipeline.valid?

      ActiveRecord::Base.transaction do
        pipeline.audits.push(audit)
        pipeline.save!
        pipeline.each(&:save!)
      end
    end
  end

  private

  def graph
    @graph ||= Graph::Builder.new(params[:jobs]).to_graph
  end

  def audit
    {
      "params" => params,
      "timestamp" => Time.zone.now
    }
  end
end
