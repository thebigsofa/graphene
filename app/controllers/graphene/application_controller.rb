# frozen_string_literal: true

module Graphene
  class ApplicationController < ActionController::API
    rescue_from ActiveRecord::RecordNotFound do |_exception|
      render nothing: true, status: 404
    end
  end
end
