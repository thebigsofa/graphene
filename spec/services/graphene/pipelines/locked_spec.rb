# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Pipelines::Locked do
  subject { described_class.new(pipeline.reload).call }

  let(:pipeline) { create(:pipeline) }

  before do
    pipeline.add_graph([Jobs::Simple]).each(&:save!)
    child_state
  end

  describe "#call" do
    context "is not locked" do
      let(:child_state) { pipeline.children.first.complete! }

      it { is_expected.to eq(false) }
    end

    context "is locked" do
      let(:child_state) { pipeline.children.first.in_progress! }

      it { is_expected.to eq(true) }
    end
  end
end
