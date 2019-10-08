# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::CallbackAggregate do
  subject { create(:pipeline, params: params) }

  let(:params) { attributes_for(:pipeline).fetch(:params) }

  let(:agg) { Graphene::CallbackAggregate.new(pipeline_id: subject.id) }

  before do
    Graphene::CallbackAggregate.create(pipeline_id: subject.id, count: 1)
  end

  describe "exists?" do
    it "returns true if exists" do
      expect(agg.exists?).to eq(true)
    end

    it "returns false if doesn't exist" do
      agg = Graphene::CallbackAggregate.new(pipeline_id: "hello")
      expect(agg.exists?).to eq(false)
    end
  end

  describe "#increment" do
    it "increments count" do
      expect(agg.increment).to eq(2)
    end
  end

  describe "#clear" do
    it "increments count" do
      expect(agg.clear).to eq(0)
    end
  end

  describe ".count_for" do
    it "returns count" do
      expect(
        Graphene::CallbackAggregate.count_for(subject.id)
      ).to eq(1)
    end
  end

  describe ".clear" do
    it "clears count" do
      expect(
        Graphene::CallbackAggregate.clear(subject.id)
      ).to eq("OK")

      expect(
        Graphene::CallbackAggregate.count_for(subject.id)
      ).to eq(0)
    end
  end
end
