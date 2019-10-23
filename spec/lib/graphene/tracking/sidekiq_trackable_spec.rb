# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Tracking::SidekiqTrackable do
  let(:subject) { described_class.call("pipeline") }
  let(:queue) { ["pipeline"] }
  before do
    subject
  end

  context "successful execution with nil timeout" do
    it "kicks off tracking job" do
      expect(Graphene::JobsTrackingDisabled.jobs.count).to eq(1)
    end

    it "sends stats" do
      expect(Graphene::JobsTrackingDisabled.jobs.first["args"]).to eq(queue)
    end

    it "sets latency cache" do
      expect(Redis.current.hgetall(:queue_data)["pipeline"]).to eq("[0,0]")
    end
  end
end
