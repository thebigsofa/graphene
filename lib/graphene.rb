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
    def call(_worker, _msg, _queue)
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

  # ENV.fetch("POLLING_TIMEOUT")

  def self.configure
    self.config ||= Config.new
    yield(config)
    self.config.sidekiq_keep_alive ||= Graphene::JobsTrackingDisabled
    self.config.sidekiq_tracking ||= Graphene::JobsTrackingDisabled
    self.config.sidekiq_tracker_queue_name ||= "pipeline_tracking"
    self.config.auth_middleware ||= Graphene::NoAuthentication
    self.config.sidekiq_callbacks_middleware ||= Graphene::SidekiqCallbacksMiddleware

    self.config.callback_delay ||= 30
    self.config.callback_auth ||= {
      method: :https,
      name: :big_sofa_auth,
      credentials: [].freeze,
      class_name: Graphene::NoAuthMiddleware
    }.freeze

    self.config.poll_timeout ||= 15.minutes

    Faraday::Request.register_middleware(
      config.callback_auth.fetch(:name, "") => (-> { config.callback_auth.fetch(:class_name, "") })
    )

    self.config.sidekiq_auth_middleware ||= Graphene::NoAuthentication
  end

  class Config
    attr_accessor(
      :sidekiq_keep_alive,
      :sidekiq_tracking,
      :sidekiq_tracker_queue_name,
      :auth_middleware,
      :mappings_and_priorities,
      :sidekiq_callbacks_middleware,
      :callback_delay,
      :callback_auth,
      :sidekiq_auth_middleware,
      :poll_timeout
    )
  end

  self.configure {}
end
