# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Jobs::Fail do
  subject { build :job, :fail }

  describe "#process" do
    let(:time) { Time.now }

    it "logs a failure" do
      Timecop.freeze(time) do
        expect { subject.process }.to raise_error(Graphene::Tasks::Task::HaltError)
        subject.save!
        subject.reload
      end
    end
  end
end
