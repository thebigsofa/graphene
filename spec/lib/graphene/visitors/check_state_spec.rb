# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Visitors::CheckState do
  let(:subject) { described_class.new }

  let(:graph) do
    [
      Graphene::Jobs::Base,
      [
        [
          Graphene::Jobs::Base,
          Graphene::Jobs::Base
        ],
        [
          Graphene::Jobs::Base,
          Graphene::Jobs::Base
        ]
      ],
      Support::Jobs::Transform::Zencoder
    ]
  end

  let(:pipeline) { build(:pipeline) }
  let(:root) { pipeline.add_graph(graph).first }

  before do
    root.each do |job|
      job.state = :complete
    end
  end

  context "no jobs marked pending" do
    before do
      subject.visit(pipeline)
    end

    it "sets no jobs to pending" do
      expect(root.map(&:state).uniq).to eq([:complete])
    end
  end

  context "root marked pending" do
    before do
      root.state = :pending
      subject.visit(pipeline)
    end

    it "sets all states to pending" do
      expect(root.map(&:state).uniq).to eq([:pending])
    end
  end

  context "nested child marked pending" do
    before do
      root.children.last.state = :pending
      subject.visit(pipeline)
    end

    it "resets the subgraph states" do
      expect(root).to be_complete
      expect(root.children[0]).to be_complete
      expect(root.children[1]).to be_pending

      expect(root.children[0].children[0]).to be_complete
      expect(root.children[1].children[0]).to be_pending

      expect(root.children[0].children[0].children[0]).to be_pending
    end
  end
end
