# frozen_string_literal: true

require_dependency "graphene/application_controller"

module Graphene
  module Ui
    class PipelinesController < ActionController::Base
      layout "graphene/application"

      def index
        @pipelines = Graphene::Pipeline.order(created_at: "DESC")
        @pipelines = filter_pipelines(@pipelines)
        @pipelines = search_pipelines(@pipelines)
        @pipelines = @pipelines.page(params.permit(:page).fetch(:page, 1)).per(20)
      end

      def show
        @pipeline = Graphene::Pipeline.find(params[:id])
      end

      private

      def filter_pipelines(pipelines)
        case params[:state]
        when "in_progress"
          pipelines.joins(:all_jobs).where("jobs.version = pipelines.version")
                   .where("jobs.state" => %i[in_progress pending retrying])
        when "failed"
          pipelines.joins(:all_jobs).where("jobs.version = pipelines.version")
                   .where("jobs.state" => [:failed])
        else
          pipelines
        end
      end

      def search_pipelines(pipelines)
        return pipelines if params[:search].blank?

        pipelines.search(params.permit(:search).fetch(:search))
      end
    end
  end
end
