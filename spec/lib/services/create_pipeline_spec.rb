# frozen_string_literal: true

require "spec_helper"

RSpec.describe CreatePipeline do
  subject { described_class.new(params) }

  describe "#call" do
    context "valid params" do
      let(:params) do
        {
          "jobs" => ["encode"],
          "encode" => {
            "media_uid" => TEST_MEDIA_UID,
            "source" => {},
            "callbacks" => {},
            "encode_options" => {},
            "type" => "upload",
            "project_uid" => "abc123"
          }
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
          "jobs" => ["encode"]
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
          "jobs" => ["encode"],
          "encode" => {}
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
          "jobs" => ["encode"]
        }
      end

      it "does not save the pipeline and jobs" do
        expect { subject.call(true) }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Pipeline.count).to eq(0)
        expect(Jobs::Base.count).to eq(0)
      end
    end
  end
end
