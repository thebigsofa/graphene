# frozen_string_literal: true

require_dependency "graphene/application_controller"

module Graphene
  module Ui
    class PipelinesController < ActionController::Base
      layout "graphene/application"

      before_action :authenticate!

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

      def authenticate!
        return unless Rails.env.production?

        authenticate_or_request_with_http_basic do |username, password|
          Rack::Utils.secure_compare(
            ::Digest::SHA256.hexdigest(username), ENV.fetch("SIDEKIQ_USERNAME")
          ) &&
            Rack::Utils.secure_compare(
              ::Digest::SHA256.hexdigest(password), ENV.fetch("SIDEKIQ_PASSWORD")
            )
        end
      end
    end
  end
end
