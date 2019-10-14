# frozen_string_literal: true

require "graphene/engine"
require "sidekiq"
require "pg_search"
require "activerecord_json_validator"

class NoAuthentication
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  end
end

class JobsTrackingDisabled
  include Sidekiq::Worker

  def perform(_)
    ::Sidekiq.logger.info("Sidekiq tracking is disabled.")
  end
end


module Graphene
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
    self.config.sidekiq_tracker ||= JobsTrackingDisabled
    self.config.auth_middleware ||= NoAuthentication
  end

  class Config
    attr_accessor :sidekiq_tracker, :auth_middleware
  end

  self.configure {}
end
