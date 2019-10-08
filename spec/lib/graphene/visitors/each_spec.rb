# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Visitors::Each do
  let(:graph) do
    [
      Jobs::Base,
      [
        [Jobs::Base],
        [Jobs::Base]
      ],
      Jobs::Base
    ]
  end

  let(:root) do
    Jobs::Base.from_graph(graph, pipeline: build(:pipeline)).first
  end

  context "persisted graph" do
    before { root.each(&:save!) }

    it "visits each node once" do
      seen = 0
      described_class.new(proc { seen += 1 }).visit(root)
      expect(seen).to eq(4)
    end
  end

  context "un-persisted graph" do
    it "visits each node once" do
      seen = 0
      described_class.new(proc { seen += 1 }).visit(root)
      expect(seen).to eq(4)
    end
  end
end
