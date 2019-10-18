# frozen_string_literal: true

require "graphene/engine"
require "activerecord_json_validator"

require "sheaf"

require "kaminari"
require "bootstrap4-kaminari-views"
require "pg_search"

require "sidekiq"
require "sidekiq/throttled"

require "faraday"
require "faraday_middleware"

module Graphene
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

  class SidekiqCallbacksMiddleware
    def call(worker, _msg, queue)
      yield
    end
  end

  class NoAuthMiddleware < Faraday::Middleware
    def initialize(app, *)
      super(app)
    end

    def call(env)
      @app.call(env)
    end
  end
end

module Graphene
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
    self.config.sidekiq_tracker ||= Graphene::JobsTrackingDisabled
    self.config.sidekiq_tracker_queue_name ||= "pipeline_tracking"
    self.config.auth_middleware ||= Graphene::NoAuthentication
    self.config.sidekiq_callbacks_middleware ||= Graphene::SidekiqCallbacksMiddleware
    self.config.callback_auth ||= {
      name: :big_sofa_auth,
      credentials: [].freeze,
      class_name: Graphene::NoAuthMiddleware
    }.freeze

    Faraday::Request.register_middleware(
      config.callback_auth => (-> { config.callback_auth.class_name })
    )
  end

  class Config
    attr_accessor(
      :sidekiq_tracker,
      :sidekiq_tracker_queue_name,
      :auth_middleware,
      :mappings_and_priorities,
      :sidekiq_callbacks_middleware,
      :callback_auth
    )
  end

  self.configure {}
end
