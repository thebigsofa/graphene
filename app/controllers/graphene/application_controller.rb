# frozen_string_literal: true

module Graphene
  class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound do |_exception|
      render body: "Not found", status: 404
    end
  end
end
