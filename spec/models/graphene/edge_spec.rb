# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Edge do
  subject { create :edge }

  describe "#origin" do
    it "is a job" do
      expect(subject.origin).to be_kind_of(Graphene::Jobs::Base)
    end
  end

  describe "#destination" do
    it "is a job" do
      expect(subject.destination).to be_kind_of(Graphene::Jobs::Base)
    end
  end
end
