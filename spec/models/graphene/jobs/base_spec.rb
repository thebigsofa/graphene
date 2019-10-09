# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Jobs::Base do
  subject { create :job }

  describe "callbacks" do
    let(:callback) do
      {
        "url" => "http://foobar.com"
      }
    end

    before do
      subject.pipeline.params = {
        "callbacks" => [callback]
      }
      Graphene::CallbackAggregate.create(pipeline_id: subject.pipeline.id, count: 1)
      subject.complete!
    end

    it "notifies all the pipeline callbacks after an update" do
      expect(Graphene::CallbackNotifierJob.jobs.count).to eq(1)
      expect(Graphene::CallbackNotifierJob.jobs.first["args"]).to eq([subject.pipeline.id, callback])
    end
  end

  describe "#audits" do
    it "validates the column type" do
      expect(subject).to be_valid
      subject.audits = {}
      expect(subject).not_to be_valid
    end

    context "state changes" do
      let(:time) { Time.now }

      let(:expected_entry) do
        {
          "type" => "state_change",
          "timestamp" => time.as_json,
          "from" => "pending",
          "to" => "in_progress",
          "version" => 1
        }
      end

      before do
        Timecop.freeze(time) do
          subject.in_progress!
        end
      end

      it "adds an entry to the audits array" do
        expect(subject.audits.size).to eq(1)
        expect(subject.audits.first).to eq(expected_entry)
      end
    end

    context "errors" do
      let(:time) { Time.now }

      let(:expected_entry) do
        {
          "error" => "StandardError",
          "error_message" => "foobar",
          "timestamp" => time.as_json,
          "type" => "error",
          "version" => 1
        }
      end

      before do
        Timecop.freeze(time) do
          subject.fail!(StandardError.new("foobar"))
        end
      end

      let(:error_audit_entry) do
        subject.audits.detect do |entry|
          entry["type"] == "error"
        end
      end

      it "adds an entry to the audits array" do
        expect(subject.audits.size).to eq(2)
        expect(error_audit_entry).to eq(expected_entry)
      end
    end
  end

  describe "#group" do
    it "defaults to the underscored class name" do
      expect(subject.group).to eq("base")
    end

    it "validates the presence" do
      subject.group = ""
      expect(subject).not_to be_valid
    end
  end

  describe "#artifacts" do
    it "default to an empty hash" do
      expect(subject.artifacts).to eq({})
    end
  end

  describe "#state" do
    it "defaults to 'pending'" do
      expect(subject.state).to eq(:pending)
      expect(subject.state_changed_at).to be_kind_of(Time)
    end
  end

  describe "#complete?" do
    context "non-complete state" do
      before { subject.update!(state: :foobar) }

      it { expect(subject).to_not(be_complete) }
    end

    context "complete state" do
      before { subject.complete! }

      it { expect(subject).to be_complete }
    end
  end

  describe "#in_progress?" do
    context "non-in_progress state" do
      before { subject.update!(state: :foobar) }

      it { expect(subject).to_not(be_in_progress) }
    end

    context "in_progress state" do
      before { subject.in_progress! }

      it { expect(subject).to be_in_progress }
    end
  end

  describe "#pending?" do
    context "non-pending state" do
      before { subject.update!(state: :foobar) }

      it { expect(subject).to_not(be_pending) }
    end

    context "pending state" do
      it { expect(subject).to be_pending }
    end
  end

  describe "#failed?" do
    context "non-failed state" do
      before { subject.update!(state: :foobar) }

      it { expect(subject).to_not(be_failed) }
    end

    context "failed state" do
      before { subject.fail!(StandardError.new) }

      it { expect(subject).to be_failed }
    end
  end

  describe "#retrying?" do
    context "non-retrying state" do
      before { subject.update!(state: :foobar) }

      it { expect(subject).to_not(be_retrying) }
    end

    context "retrying state" do
      before { subject.retrying!(StandardError.new) }

      it { expect(subject).to be_retrying }
    end
  end

  describe "#children" do
    let(:child) { create(:job) }

    it "creates the correct association" do
      subject.children << child

      expect(subject.children.count).to eq(1)
      expect(subject.children.first).to eq(child)

      expect(subject.parents.count).to eq(0)

      expect(child.parents.count).to eq(1)
      expect(child.parents.first).to eq(subject)
    end
  end

  describe "#parents" do
    let(:parent) { create(:job) }

    it "creates the correct association" do
      subject.parents << parent

      expect(subject.parents.count).to eq(1)
      expect(subject.parents.first).to eq(parent)

      expect(subject.children.count).to eq(0)

      expect(parent.children.count).to eq(1)
      expect(parent.children.first).to eq(subject)
    end
  end

  describe "#destroy with associations" do
    let(:child) { create(:job) }
    let(:parent) { create(:job) }

    before do
      subject.children << child
      subject.parents << parent
    end

    it "destroys the edges" do
      expect(Graphene::Edge.count).to eq(2)

      subject.destroy!

      expect(Graphene::Edge.count).to eq(0)
    end
  end

  describe "Enumerable" do
    let(:root) { create(:job) }

    before do
      root.children << create(:job)
      root.children << create(:job)
      root.children.each_with_object(create(:job)) do |child, job|
        child.children << job
      end
    end

    it "yields each object" do
      jobs = root.map { |_job| self }
      expect(jobs.count).to eq(4)
    end
  end

  describe ".from_graph" do
    let(:pipeline) { create(:pipeline, version: 3) }

    context "single node" do
      let(:graph) do
        [Graphene::Jobs::Base]
      end

      let(:root) { described_class.from_graph(graph, pipeline: pipeline).first }

      it "builds the given graph" do
        expect(root.children.size).to eq(0)
      end
    end

    context "linear" do
      let(:graph) do
        [
          Graphene::Jobs::Base,
          Graphene::Jobs::Base,
          Graphene::Jobs::Base
        ]
      end

      let(:root) { described_class.from_graph(graph, pipeline: pipeline).first }

      it "creates the given graph" do
        expect(root.children.size).to eq(1)
        expect(root.children.first.children.size).to eq(1)
        expect(root.children.first.children.first.children.size).to eq(0)
        expect(root.map(&:version).uniq).to eq([3])
      end

      it "assigns the pipeline's version to each job" do
        expect(root.map(&:version).uniq).to eq([3])
      end

      it "does not create duplicate vertices" do
        expect(root.count).to eq(3)
      end

      it "does not persist any vertices" do
        expect(root.all?(&:persisted?)).to eq(false)
      end

      it "assigns the same pipeline to each job" do
        expect(root.map(&:pipeline).uniq.compact.size).to eq(1)
      end
    end

    context "non-linear" do
      let(:graph) do
        [
          Graphene::Jobs::Base,
          [
            [Graphene::Jobs::Base],
            [Graphene::Jobs::Base]
          ],
          Graphene::Jobs::Base
        ]
      end

      let(:root) { described_class.from_graph(graph, pipeline: pipeline).first }

      it "creates the given graph" do
        expect(root.children.size).to eq(2)
        root.children.each do |child|
          expect(child.children.size).to eq(1)
          expect(child.children.first.children.size).to eq(0)
        end
      end

      it "assigns the pipeline's version to each job" do
        expect(root.map(&:version).uniq).to eq([3])
      end

      it "does not create duplicate vertices" do
        expect(root.count).to eq(4)
      end

      it "does not persist any vertices" do
        expect(root.all?(&:persisted?)).to eq(false)
      end

      it "assigns the same pipeline to each job" do
        expect(root.map(&:pipeline).uniq.compact.count).to eq(1)
      end
    end

    context "mixed types" do
      let(:graph) do
        [
          Graphene::Jobs::Base,
          Support::Jobs::DoNothing
        ]
      end

      let(:root) { described_class.from_graph(graph, pipeline: pipeline).first }

      it "sets the correct types" do
        expect(root).to be_kind_of(Graphene::Jobs::Base)
        expect(root.children.first).to be_kind_of(Support::Jobs::DoNothing)
      end

      it "assigns the pipeline's version to each job" do
        expect(root.map(&:version).uniq).to eq([3])
      end

      it "assigns the same pipeline to each job" do
        expect(root.map(&:pipeline).uniq.compact.count).to eq(1)
      end
    end
  end
end
