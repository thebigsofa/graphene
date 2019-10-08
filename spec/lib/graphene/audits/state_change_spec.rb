# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Audits::StateChange do
  let(:job) { build(:job) }

  subject { described_class.new(job, "foo", "bar") }

  let(:expected) do
    {
      version: job.version,
      type: "state_change",
      timestamp: Time.now,
      from: "foo",
      to: "bar"
    }
  end

  describe "to_h" do
    it "returns the correct hash" do
      Timecop.freeze do
        expect(subject.to_h).to eq(expected)
      end
    end
  end
end
