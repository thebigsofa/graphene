# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipeline do
  subject { create(:pipeline, params: params) }

  let(:params) { attributes_for(:pipeline).fetch(:params) }

  describe "#add_graph" do
    context "linear" do
      let(:graph) { [Graphene::Jobs::Base, Graphene::Jobs::Base, Graphene::Jobs::Base] }
      let!(:root) { subject.add_graph(graph).first }

      it "does not create duplicate vertices" do
        expect(root.count).to eq(3)
      end

      it "assigns the jobs to the pipeline jobs" do
        expect(subject.jobs.size).to eq(3)
      end

      it "assigns the root to the pipeline children" do
        expect(subject.children.size).to eq(1)
        expect(subject.children.first).to eq(root)
      end

      it "does not persist all vertices" do
        expect(root.any?(&:persisted?)).to eq(false)
      end

      it "assigns the same pipeline to each job" do
        root.each do |job|
          expect(job.pipeline).to eq(subject)
        end
      end
    end
  end

  describe "#increment_version_and_add_graph" do
    let(:graph) { [Jobs::Base, Jobs::Transform::Zencoder] }

    context "in-memory" do
      before do
        subject.add_graph(graph).first.each(&:save!)
        subject.increment_version_and_add_graph(graph)
      end

      it "updates the pipeline version and adds the new graph" do
        expect(subject.version).to eq(2)
        expect(subject.persisted?).to eq(true)
        expect(subject.changed?).to eq(true)

        expect(subject.children.size).to eq(1)
        expect(subject.children.map(&:version).uniq).to eq([2])
        expect(subject.children.any?(&:persisted?)).to eq(false)

        expect(subject.jobs.size).to eq(2)
        expect(subject.jobs.map(&:version).uniq).to eq([2])
        expect(subject.jobs.any?(&:persisted?)).to eq(false)

        expect(subject.jobs.map(&:class)).to eq(graph)
      end
    end

    context "saving" do
      before do
        subject.add_graph(graph).first.each(&:save!)
        subject.increment_version_and_add_graph(graph)
        subject.save!
        subject.jobs.each(&:save!)
        subject.reload
      end

      it "updates the pipeline version and saves the new graph" do
        expect(subject.version).to eq(2)
        expect(subject.persisted?).to eq(true)

        expect(subject.children.map(&:version).uniq).to eq([2])
        expect(subject.children.size).to eq(1)
        expect(subject.children.all?(&:persisted?)).to eq(true)

        expect(subject.jobs.map(&:version).uniq).to eq([2])
        expect(subject.jobs.size).to eq(2)
        expect(subject.jobs.all?(&:persisted?)).to eq(true)

        expect(subject.jobs.map(&:class)).to include(*graph)
      end
    end

    context "attribute matching" do
      before do
        root = subject.add_graph(graph).first
        root.state = "complete"
        root.children.first.state = "failed"
        subject.each(&:save!)
        subject.increment_version_and_add_graph(graph)
      end

      it "matches the attributes from matching jobs to the new graph" do
        expect(subject.jobs.first.state).to eq(:complete)
        expect(subject.jobs.last.state).to eq(:failed)
      end
    end
  end

  describe "#jobs" do
    let(:root) { subject.add_graph([Jobs::Base, Jobs::Base, Jobs::Base]).first }

    before { root.each(&:save!) }

    it "returns all jobs with the same version as the pipeline" do
      expect(subject.jobs.count).to eq(3)
      subject.update!(version: subject.version += 1)
      expect(subject.jobs.count).to eq(0)
      root.each { |job| job.update!(version: subject.version) }
      expect(subject.jobs.count).to eq(3)
    end
  end

  describe "#children" do
    let(:root) { subject.add_graph([Jobs::Base, Jobs::Base]).first }

    before { root.each(&:save!) }

    it "returns all children with the same version as the pipeline" do
      expect(subject.children.count).to eq(1)
      subject.update!(version: subject.version += 1)
      expect(subject.children.count).to eq(0)
      root.each { |job| job.update!(version: subject.version) }
      expect(subject.children.count).to eq(1)
    end
  end

  describe "#children" do
    let(:graph) { [Jobs::Base, Jobs::Base, Jobs::Base] }

    before do
      subject.add_graph(graph).each(&:save!)
    end

    it "returns all root vertices" do
      expect(subject.children.size).to eq(1)
    end
  end

  describe "enumerable" do
    let(:graph) { [Jobs::Base, Jobs::Base, Jobs::Base] }

    before do
      subject.add_graph(graph).each(&:save!)
    end

    it "yields all jobs" do
      expect(subject.map(&:class)).to eq(graph)
    end
  end

  describe "#accept" do
    let(:graph) { [Jobs::Base, Jobs::Base, Jobs::Base] }

    before do
      subject.add_graph(graph).each(&:save!)
      subject.accept(SidekiqVisitor.new)
    end

    it "visits each child" do
      expect(SidekiqVisitor.jobs.count).to eq(1)
    end
  end

  describe "#to_dot" do
    let(:dot) { subject.to_dot }
    let(:expected) do
      <<~EODOT.strip
        digraph "Graph" {
        node [width=0.375,height=0.25,shape = "record"];
        1 [label="<f0> Pipeline", fontcolor=black, color=black];
        }
      EODOT
    end

    it "returns a graphviz graph" do
      expect(dot).to eq(expected)
    end
  end

  describe "#notify_callbacks!" do
    let(:params) do
      attributes_for(:pipeline).fetch(:params).merge(
        callbacks: [
          { url: "http://foobar.com/" }
        ]
      )
    end

    before do
      subject.update!(params: params)
    end

    it "enqueues notification jobs" do
      expect(CallbackNotifierJob.jobs.count).to eq(2)
      expect(CallbackNotifierJob.jobs.first["args"])
        .to eq([subject.id, "url" => "http://foobar.com/"])
    end
  end

  describe "aggregate callbacks" do
    let(:params) do
      attributes_for(:pipeline).fetch(:params).merge(
        callbacks: [
          { url: "http://foobar.com/" }
        ]
      )
    end

    before do
      subject.update!(params: params)
    end

    it "enqueues notification jobs" do
      expect(CallbackNotifierJob.jobs.count).to eq(2)
      expect(
        CallbackAggregate.count_for(subject.id)
      ).to eq(2)

      expect_any_instance_of(
        CallbackNotifierJob
      ).to receive(:connection).exactly(1).times.and_call_original

      VCR.use_cassette("models/pipeline/callback") do
        CallbackNotifierJob.drain
      end

      expect(
        CallbackAggregate.count_for(subject.id)
      ).to eq(0)
    end
  end

  describe "#queue" do
    it "has a correct queue" do
      expect(subject.queue).to eq(:pipeline)
    end
  end
end
