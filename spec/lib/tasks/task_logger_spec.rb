# frozen_string_literal: true

require "spec_helper"

RSpec.describe TaskLogger do
  let(:job) { create :job }
  let(:logger) { Logger.new(nil) }

  subject { described_class.new(job, logger) }

  context "default logger" do
    subject { described_class.new(job) }

    it "assigns the rails logger by default" do
      expect(subject.logger).to eq(Rails.logger)
    end

    described_class::LOG_METHODS.each do |meth|
      it "the #{meth} method" do
        expect(subject.logger).to respond_to(meth)
      end
    end
  end

  context "sidekiq logger" do
    subject { described_class.new(job) }

    before do
      allow(Sidekiq).to receive(:logger).and_return(logger)
      allow(Sidekiq).to receive(:server?).and_return(true)
    end

    it "assigns the rails logger when running in sidekiq" do
      expect(subject.logger).to eq(logger)
    end
  end

  describe "method_missing" do
    let(:message) { "foobar" }

    let(:time) { Time.now }

    let(:expected_audit) do
      {
        type: :log,
        level: :info,
        message: message,
        timestamp: time.to_json
      }
    end

    let(:formatted_message) do
      [
        "pipeline",
        job.pipeline_id,
        "job",
        job.class.name,
        job.id,
        "foobar"
      ].join(" ")
    end

    it "assigns an audit entry when logging and delegates to the logger" do
      expect(logger).to receive(:info).with(formatted_message).once
      Timecop.freeze(time) { subject.info(message) }
      expect(job.audits.size).to eq(1)
    end
  end
end
