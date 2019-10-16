# frozen_string_literal: true

require "spec_helper"

RSpec.describe Jobs::Fail do
  subject { build :job, :fail }

  describe "#process" do
    let(:time) { Time.now }

    let(:expected_log_message) do
      {
        "level" => "error",
        "message" => "Tasks::Helpers::Fail failing",
        "timestamp" => time.as_json,
        "type" => "log",
        "version" => 1
      }
    end

    before do
      Timecop.freeze(time) do
        expect { subject.process }.to raise_error(Task::HaltError)
        subject.save!
        subject.reload
      end
    end

    it "logs a failure" do
      expect(subject.audits.size).to eq(1)
      expect(subject.audits.first).to eq(expected_log_message)
    end
  end
end
