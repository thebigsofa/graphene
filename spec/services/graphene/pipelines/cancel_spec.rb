# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipelines::Cancel do
  subject { described_class.new(pipeline) }

  let(:data) do
    { simple: [1,2,3,4], smooth: 3.14 }
  end

  context "updating pipeline" do
    let(:pipeline_params) do
      {
        jobs: %w[simple smooth],
        simple: { data: data },
        smooth: { data: data },
        callbacks: [{}]
      }
    end

    let(:pipeline) do
      create(:pipeline, params: pipeline_params)
    end

    let!(:simple_job) do
      create(:job, :simple, state: :in_progress, pipeline: pipeline)
    end

    let!(:smooth_job) do
      create(:job, :smooth, state: :pending, pipeline: pipeline)
    end

    let(:result) { subject.call }

    it "updates states" do
      expect(result).to eq(true)
      expect(pipeline.jobs.map(&:state).uniq).to eq([:cancelled])
      expect(Graphene::CallbackNotifierJob.jobs.count).to eq(4)
    end
  end
end
