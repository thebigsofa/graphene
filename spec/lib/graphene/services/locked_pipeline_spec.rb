# frozen_string_literal: true

require "spec_helper"

RSpec.describe LockedPipeline do
  subject(:klass) { described_class.new(pipeline) }

  let(:pipeline) { create(:pipeline) }

  before do
    pipeline.add_graph([Jobs::Transform::Zencoder]).each(&:save!)
    child_state
  end

  describe "#call" do
    context "is not locked" do
      let(:child_state) { pipeline.children.first.complete! }

      it { expect(klass.call).to eq(false) }
    end

    context "is locked" do
      let(:child_state) { pipeline.children.first.in_progress! }

      it { expect(klass.call).to eq(true) }
    end
  end
end
