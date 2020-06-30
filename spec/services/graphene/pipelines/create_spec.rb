# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipelines::Create do
  subject { described_class.new(params) }

  let(:data) do
    { simple: [1, 2, 3, 4], smooth: 3.14 }
  end

  describe "#call" do
    context "valid params" do
      let(:params) do
        {
          "jobs" => ["simple"],
          "simple" => { data: data }
        }
      end

      let(:pipeline) { subject.call }

      it "creates a pipeline with the given graph" do
        expect(pipeline).to be_persisted
        expect(pipeline.count).to eq(1)
      end
    end

    context "missing top-level params" do
      let(:params) do
        {
          "jobs" => ["simple"]
        }
      end

      let(:pipeline) { subject.call }

      it "does not save the pipeline and jobs" do
        expect(pipeline).not_to be_persisted
        expect(pipeline.count).to eq(1)
        expect(pipeline.any?(&:persisted?)).to eq(false)
      end
    end

    context "missing second-level params" do
      let(:params) do
        {
          "jobs" => ["simple"],
          "simple" => {}
        }
      end

      let(:pipeline) { subject.call }

      it "does not save the pipeline and jobs" do
        expect(pipeline).not_to be_persisted
        expect(pipeline.count).to eq(1)
        expect(pipeline.any?(&:persisted?)).to eq(false)
      end
    end

    context "missing params with raise_error flat" do
      let(:params) do
        {
          "jobs" => ["simple"]
        }
      end

      it "does not save the pipeline and jobs" do
        expect { subject.call(true) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Graphene::Pipeline.count).to eq(0)
        expect(Graphene::Jobs::Base.count).to eq(0)
      end
    end

    context "with identifer but no indentifier_type" do
      let(:params) do
        {
          "jobs" => ["simple"],
          "simple" => { data: data },
          "identifier" => {
            "value" => "sausage"
          }
        }
      end

      let(:pipeline) { subject.call }

      it "does not save the pipeline and jobs" do
        expect(pipeline.identifier).to eq("sausage")
        expect(pipeline.identifier_type).to be_empty
      end
    end

    context "with identifer but no indentifier_type" do
      let(:params) do
        {
          "jobs" => ["simple"],
          "simple" => { data: data },
          "identifier" => {
            "value" => "sausage",
            "type" => "media uid"
          }
        }
      end

      let(:pipeline) { subject.call }

      it "does not save the pipeline and jobs" do
        expect(pipeline.identifier).to eq("sausage")
        expect(pipeline.identifier_type).to eq("media uid")
      end
    end
  end
end
