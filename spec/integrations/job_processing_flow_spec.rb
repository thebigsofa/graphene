# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Enqueue and process a job (class name amd job name are different)" do
  let(:pipeline_params) do
    {
      "jobs" => ["encode"],
      "encode" => {
        "media_uid" => "a03qq7",
        "callbacks" => {
          "mp4" => {
            "url" => ""
          },
          "mp3" => {
            "url" => ""
          },
          "compressed_mp4" => {
            "url" => ""
          }
        },
        "source" => {
          "url" => "",
          "filename" => ""
        },
        "type" => "upload",
        "project_uid" => "abc123"
      }
    }
  end

  # let(:pipeline) do
  #   Graphene::Pipelines::Create.new(pipeline_params).call
  # end

  # FIXME: How to fix this bug???
  # Adding pipeline.reload in the Graphene::Pipelines::Create#call
  # method after pipeline.save!
  # or
  # here in the spec
  # makes it all pass.
  # But that is not the best solution.
  # specify do
  #   expect(pipeline).to be_persisted
  #   expect(pipeline.jobs.map(&:group)).to eq(["encode"])

  #   # Graphene::Visitors::Sidekiq.drain
  # end

  specify do
    # When a pipeline is created
    pipeline = Graphene::Pipelines::Create.new(pipeline_params).call

    # Then it should be persisted
    expect(pipeline).to be_persisted

    # and locked
    expect(Graphene::Pipelines::Locked.new(pipeline.reload).call).to eq(true)

    # When sidekiq visitor does its processing
    Graphene::Visitors::Sidekiq.new.visit(pipeline)
    Graphene::Visitors::Sidekiq.drain

    # the pipeline should create jobs in the DB
    expect(pipeline.jobs.map(&:group)).to eq(["encode"])
    expect(pipeline.params["encode"]["encode_options"]).to eq(nil)

    # and it should finish them successfully.
    expect(pipeline.jobs.map(&:state)).to eq([:complete])

    # and pipeline should not be locked any more
    expect(Graphene::Pipelines::Locked.new(pipeline.reload).call).to eq(false)

    # When the pipeline is updated
    update_params = pipeline_params.deep_dup
    update_params["encode"]["encode_options"] = { "rotate" => 90 }
    update_params["jobs"] = %w[encode simple]
    update_params["simple"] = { "data" => { "simple" => [1, 2, 3, 4], "smooth" => 3.14 } }

    expect(Graphene::Pipelines::Update.new(pipeline.reload, update_params).call).to eq(true)

    # Then the params should be updated
    expect(pipeline.reload.audits.count).to eq(2)
    expect(pipeline.params["encode"]["encode_options"]).to eq("rotate" => 90)
    expect(pipeline.params["jobs"]).to include("simple")

    # and the pipeline should be locked
    expect(Graphene::Pipelines::Locked.new(pipeline.reload).call).to eq(true)

    # and the jobs should be waiting for processing
    expect(pipeline.reload.jobs.map(&:state)).to eq(%i[pending pending])

    # When it's finished processing again
    Graphene::Visitors::Sidekiq.drain

    # Then all jobs should be completed again
    expect(pipeline.reload.jobs.map(&:state)).to eq(%i[complete complete])
  end

  it "can add new graph - in theory this is not needed but it shows exact issue we had" do
    # The new_graph could not be added into the graph in some situations
    # So this test should be kept.
    pipeline = Graphene::Pipelines::Create.new(pipeline_params).call

    expect(pipeline.jobs.count).to eq(1)

    new_graph = Graphene::Graph::Builder.new(
      %w[encode simple],
      mapping: Graphene::Pipelines::Config.mapping("default"),
      priorities: Graphene::Pipelines::Config.priorities("default")
    ).to_graph

    pipeline.add_graph(new_graph)
    pipeline.jobs.map(&:save!)

    expect(pipeline.jobs.count).to eq(3)
    expect(pipeline.reload.jobs.map(&:persisted?)).to eq([true, true, true])
    expect(pipeline.reload.jobs.map(&:children).flatten.first.class).to eq(Jobs::Simple)
  end
end
