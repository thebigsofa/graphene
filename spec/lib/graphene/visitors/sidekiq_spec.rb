# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Visitors::Sidekiq do
  let(:pipeline) { create(:pipeline) }
  let(:root) do
    Graphene::Jobs::Base.from_graph([Graphene::Jobs::Base, Graphene::Jobs::Base], pipeline: pipeline).first.tap do |root|
      root.each(&:save!)
    end
  end

  describe "#perform" do
    it "finds the job and processes it" do
      expect(subject).to receive(:process).with(root, 0, false).once
      subject.perform(root.to_global_id.to_s)
    end

    context "given a pipeline" do
      let(:pipeline_params) do
        attributes_for(:pipeline).fetch(:params)
      end

      let(:pipeline) { Graphene::Pipeline.from_params_and_graph(pipeline_params, [Graphene::Jobs::Base]) }
      let(:job_id) { pipeline.children.first.to_global_id.to_s }

      before do
        pipeline.each(&:save!)
        subject.perform(pipeline.to_global_id.to_s)
      end

      it "enqueues sub jobs" do
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([job_id])
      end
    end
  end

  describe "#process" do
    context "success" do
      let(:child_gid) { root.children.first.to_global_id.to_s }

      before { subject.process(root) }

      it "processes the job" do
        expect(root).to be_complete
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([child_gid])
      end
    end

    context "halt" do
      let(:root) do
        Graphene::Jobs::Base.from_graph([Graphene::Jobs::Fail], pipeline: pipeline).first.tap do |root|
          root.each(&:save!)
        end
      end

      before do
        subject.process(root)
      end

      it "sets the job to failed" do
        expect(root).to be_failed
        expect(root.error).to eq("Graphene::Tasks::Helpers::Fail::Error")
        expect(root.error_message).to eq("forced failure")
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      end
    end

    context "already in progress" do
      before do
        root.in_progress!
        subject.process(root)
      end

      it "does not processes the job" do
        expect(root).to be_in_progress
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      end
    end

    context "when cancelled" do
      before do
        root.cancel!
        subject.process(root)
      end

      it "does not processes the job" do
        expect(root).to be_cancelled
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      end
    end

    context "parents failed" do
      let(:job) { root.children.first }

      let!(:child) { create(:job, pipeline: pipeline, parents: [job]) }

      before do
        root.fail!(StandardError.new("foobar"))
        subject.process(job)
      end

      it "sets the job as failed" do
        expect(job).to be_failed
        expect(job.error).to eq("Graphene::Jobs::DependencyError")
        expect(job.error_message).to eq("one or more parent jobs failed")
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([child.to_global_id.to_s])
      end
    end

    context "parents incomplete" do
      let(:job) { root.children.first }

      before { subject.process(job) }

      it "does not processes the job" do
        expect(job).to be_pending
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      end
    end

    context "failure with retries exhausted" do
      before do
        root.retrying!(StandardError.new)
        allow(root).to receive(:process) { raise StandardError, "foobar" }
        expect { subject.process(root, described_class::MAX_RETRIES) }
          .to raise_error(StandardError)
      end

      let(:child) { root.children.first }

      it "sets the job to failed" do
        expect(root).to be_failed
        expect(root.error).to eq("StandardError")
        expect(root.error_message).to eq("foobar")
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([child.to_global_id.to_s])
      end
    end

    context "failure with retries not exhausted" do
      let(:retries) { described_class::MAX_RETRIES - 1 }

      before do
        Timecop.freeze(Time.now)
        allow(root).to receive(:process) { raise StandardError, "foobar" }
        allow(subject).to receive(:retry_delay).with(retries).and_return(5.minutes)
        expect { subject.process(root, retries) }.to raise_error(StandardError)
      end

      after { Timecop.return }

      it "enqueues a retry job" do
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([root.to_global_id.to_s, retries + 1])
        expect(Graphene::Visitors::Sidekiq.jobs.first["at"]).to eq((Time.now + 5.minutes).to_f)
        expect(root).to be_retrying
        expect(root.error).to eq("StandardError")
        expect(root.error_message).to eq("foobar")
      end
    end

    context "retries on ActiveRecord Error" do
      let(:retries) { described_class::MAX_RETRIES - 1 }

      before do
        Timecop.freeze(Time.now)
        allow(root).to receive(:process) { raise ActiveRecord::StatementInvalid, "foobar" }
      end

      after { Timecop.return }

      it "enqueues a retry job" do
        subject.process(root, retries)
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([root.to_global_id.to_s, 5, true])
        expect(root.reload).to be_in_progress
        Graphene::Visitors::Sidekiq.drain
        expect(root.reload).to be_complete
      end
    end

    context "0 retries with job marked as retrying" do
      before do
        root.retrying!(StandardError.new)
        subject.process(root)
      end

      it "does not processes the job" do
        expect(root).to be_retrying
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(0)
      end
    end

    context "already complete" do
      let(:child) { root.children.first }

      before do
        root.complete!
        expect(root).not_to receive(:process)
        subject.process(root)
      end

      it "enqueues the child jobs" do
        expect(Graphene::Visitors::Sidekiq.jobs.count).to eq(1)
        expect(Graphene::Visitors::Sidekiq.jobs.first["args"]).to eq([child.to_global_id.to_s])
      end
    end
  end
end
