# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graph::JobTemplate do
  let(:pipeline) { build(:pipeline) }
  let(:job_klass) { Jobs::Base }

  context "given a group name" do
    let(:group) { "foo" }

    subject { described_class.new(job_klass, group).new(pipeline: pipeline) }

    it "assigns the group to the job" do
      expect(subject).to be_kind_of(job_klass)
      expect(subject).to be_valid
      expect(subject.group).to eq(group)
      expect(subject.pipeline).to eq(pipeline)
    end
  end

  context "given no group name" do
    subject { described_class.new(job_klass).new(pipeline: pipeline) }

    it "assigns the group to the job" do
      expect(subject).to be_kind_of(job_klass)
      expect(subject).to be_valid
      expect(subject.group).to eq("base")
      expect(subject.pipeline).to eq(pipeline)
    end
  end
end
