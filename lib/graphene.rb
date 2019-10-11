# frozen_string_literal: true

require "graphene/engine"

class NoAuthentication
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  end
end

module Graphene
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
    self.config.sidekiq_tracker ||= Graphene::Tracking::Disabled
    self.config.auth_middleware ||= NoAuthentication
  end

  class Config
    attr_accessor :sidekiq_tracker, :auth_middleware
  end
end
