# frozen_string_literal: true

require_dependency "graphene/application_controller"

module Graphene
  class ServiceStatusController < ActionController::Base
    layout false

    def status
      render template: "graphene/service_status/show"
    end
  end
end
