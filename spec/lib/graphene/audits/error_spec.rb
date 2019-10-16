# frozen_string_literal: true

require "spec_helper"

RSpec.describe Audits::Error do
  let(:job) { build(:job) }

  subject { described_class.new(job, "foo", "bar") }

  let(:expected) do
    {
      version: job.version,
      type: "error",
      timestamp: Time.now,
      error: "foo",
      error_message: "bar"
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
