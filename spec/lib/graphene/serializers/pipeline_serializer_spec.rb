# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Serializers::PipelineSerializer do
  subject { described_class.new(pipeline) }

  {
    failed: [
      %i[complete failed],
      [:failed]
    ],
    retrying: [
      %i[complete retrying],
      %i[retrying failed]
    ],
    in_progress: [
      %i[in_progress retrying],
      %i[in_progress failed],
      %i[complete in_progress],
      %i[in_progress pending]
    ],
    complete: [
      [:complete]
    ],
    pending: [
      [:pending],
      %i[pending failed]
    ]
  }.each do |flag, state_groups|
    state_groups.each do |states|
      context "when job states are: #{states}" do
        let(:pipeline) { create(:pipeline) }

        before do
          pipeline.add_graph(states.map { Graphene::Jobs::Base }).first.each_with_index do |job, i|
            job.state = states[i]
            job.save!
          end
        end

        let(:serialized) { JSON.parse(subject.to_json) }

        it "returns '#{flag}' as the state" do
          expect(serialized.dig("jobs", "base", "state")).to eq(flag.to_s)
        end
      end
    end
  end

  describe "to_json" do
    let(:audit_params) do
      {
        "media_uid" => "0e6a96f5ba8c",
        "jobs" => ["encode"],
        "controller" => "pipelines",
        "action" => "create",
        "pipeline" => {}
      }
    end

    let(:pipeline) { create(:pipeline, audit_params: audit_params) }

    let(:time) { Time.now }

    let(:serialized) do
      Timecop.freeze(time) { JSON.parse(subject.to_json) }
    end

    let(:expected) do
      {
        "id" => pipeline.id,
        "timestamp" => time.as_json,
        "version" => 1,
        "state" => "in_progress",
        "jobs" => {
          "simple" => {
            "version" => 1,
            "errors" => [],
            "state" => "in_progress",
            "children" => %w[smooth encode],
            "parents" => [],
            "audits" => [
              {
                "type" => "state_change",
                "version" => 1,
                "from" => "pending",
                "to" => "in_progress",
                "job" => "Jobs::Simple",
                "job_id" => root.id,
                "timestamp" => time.as_json
              }
            ],
            "artifacts" => {}
          },
          "smooth" => {
            "version" => 1,
            "errors" => [],
            "state" => "pending",
            "children" => [],
            "parents" => ["simple"],
            "audits" => [],
            "artifacts" => {}
          },
          "encode" => {
            "version" => 1,
            "errors" => [],
            "state" => "pending",
            "children" => [],
            "parents" => ["simple"],
            "audits" => [],
            "artifacts" => {}
          }
        },
        "params" => pipeline.params.stringify_keys,
        "audits" => [{
          "params" => audit_params,
          "timestamp" => time.as_json
        }]
      }
    end

    let(:graph) do
      [
        Jobs::Simple,
        [
          [Jobs::Smooth],
          [Jobs::Encode]
        ]
      ]
    end

    let(:root) { pipeline.add_graph(graph).first }

    before do
      Timecop.freeze(time) do
        root.each(&:save!)
        root.in_progress!
      end
    end

    it "returns the correct JSON" do
      expect(serialized).to eq(expected)
    end
  end
end
