# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Visitors::Dot do
  let(:subject) { described_class.new }

  let(:graph) do
    [
      Graphene::Jobs::Base,
      [
        [
          Support::Jobs::Transform::Zencoder
        ],
        [
          Support::Jobs::Transform::Zencoder
        ]
      ],
      Graphene::Jobs::Base
    ]
  end

  let(:pipeline) { build(:pipeline) }
  let(:root) { pipeline.add_graph(graph).first }

  before do
    root.state = :complete
    root.children.first.state = :failed
    root.children.last.state = :in_progress
    subject.visit(pipeline)
  end

  it "renders the correct dot file" do
    expected = <<~EODOT.strip
      digraph "Graph" {
      node [width=0.375,height=0.25,shape = "record"];
      1 [label="<f0> Graphene::Pipeline", fontcolor=black, color=black];
      2 [label="<f0> Graphene::Jobs::Base", fontcolor=darkgreen, color=darkgreen];
      3 [label="<f0> Support::Jobs::Transform::Zencoder", fontcolor=firebrick1, color=firebrick1];
      4 [label="<f0> Graphene::Jobs::Base", fontcolor=black, color=black];
      5 [label="<f0> Support::Jobs::Transform::Zencoder", fontcolor=goldenrod1, color=goldenrod1];
      1 -> 2 [color=darkgreen];
      2 -> 3 [color=firebrick1];
      3 -> 4 [color=black];
      2 -> 5 [color=goldenrod1];
      5 -> 4 [color=black];
      }
    EODOT

    expect(subject.to_dot).to eq(expected)
  end
end
