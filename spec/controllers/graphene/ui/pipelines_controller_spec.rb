# frozen_string_literal: true

require "spec_helper"

RSpec.describe Graphene::Ui::PipelinesController, type: :controller do
  routes { Graphene::Engine.routes }

  describe "GET #show" do
    let(:pipeline) { create(:pipeline) }

    before do
      get :show, params: { id: pipeline.id }
    end

    it "returns the correct response" do
      expect(response).to have_http_status(:success)
      expect(@controller.view_assigns["pipeline"]).to eq(pipeline)
    end
  end

  describe "GET #index" do
    let(:pipelines) { @controller.view_assigns["pipelines"].to_a }

    context "regular request" do
      before do
        create(:pipeline)
        get :index
      end

      it "returns the correct response" do
        expect(response).to have_http_status(:success)
        expect(pipelines).to eq(Graphene::Pipeline.all)
        expect(pipelines.size).to eq(1)
      end
    end

    context "returns paginated pipelines" do
      before do
        create_list(:pipeline, 26)
      end

      it "returns 20 pipelines" do
        get :index
        expect(pipelines.count).to eq(20)
      end

      it "returns the last 6 pipelines" do
        get :index, params: { page: 2 }
        expect(pipelines.count).to eq(6)
      end
    end

    context "search request" do
      let!(:pipeline_a) do
        create(:pipeline, identifier: "sausage")
      end

      before do
        create(:pipeline)
        get :index, params: { search: "sausage" }
      end

      it "returns the correct response" do
        expect(response).to have_http_status(:success)
        expect(pipelines).to eq([pipeline_a])
        expect(pipelines.size).to eq(1)
      end
    end

    context "in progress filter" do
      let!(:pipeline_a) do
        create(:pipeline).tap do |pipeline|
          pipeline.add_graph([Graphene::Jobs::Base]).first.state = :in_progress
          pipeline.each(&:save!)
        end
      end

      before do
        create(:pipeline).tap do |pipeline|
          pipeline.add_graph([Graphene::Jobs::Base]).first.state = :complete
        end

        get :index, params: { state: "in_progress" }
      end

      it "returns the correct response" do
        expect(response).to have_http_status(:success)
        expect(pipelines).to eq([pipeline_a])
        expect(pipelines.size).to eq(1)
      end
    end

    context "failed filter" do
      let!(:pipeline_a) do
        create(:pipeline).tap do |pipeline|
          pipeline.add_graph([Graphene::Jobs::Base, Graphene::Jobs::Base])
          pipeline.jobs.first.state = :in_progress
          pipeline.jobs.last.state = :failed
          pipeline.each(&:save!)
        end
      end

      before do
        create(:pipeline).tap do |pipeline|
          pipeline.add_graph([Graphene::Jobs::Base]).first.state = :complete
        end

        get :index, params: { state: "failed" }
      end

      it "returns the correct response" do
        expect(response).to have_http_status(:success)
        expect(pipelines).to eq([pipeline_a])
        expect(pipelines.size).to eq(1)
      end
    end
  end
end
