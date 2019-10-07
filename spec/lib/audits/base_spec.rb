# frozen_string_literal: true

require "spec_helper"

RSpec.describe Audits::Base do
  let(:job) { build(:job) }

  subject { described_class.new(job) }

  let(:expected) do
    {
      version: job.version,
      type: "base",
      timestamp: Time.now
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
