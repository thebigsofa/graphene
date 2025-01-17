ENV["REDIS_URL"] ||= "redis://redis:6379"
ENV["REDIS_DB"] ||= "1"

require "sidekiq"
require "sidekiq/throttled"
Sidekiq::Throttled.setup!
Sidekiq::Client.reliable_push! unless Rails.env.test?

Redis.current = Redis.new(db: ENV.fetch("REDIS_DB"))

redis_url = "#{ENV.fetch("REDIS_URL")}/#{ENV.fetch("REDIS_DB")}"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.super_fetch!
  config.reliable_scheduler!
  config.server_middleware do |chain|
    chain.add(Graphene.config.sidekiq_callbacks_middleware)
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

class DefaultMappingAndPriorities
  def self.mapping
    {
      "encode" => [[Jobs::Transform::Zencoder]],
      "simple" => [[Jobs::Simple]],
      "smooth" => [[Jobs::Smooth]],
      "unite_data" => [[Jobs::UniteData]]
    }.freeze
  end

  def self.priorities
    {
      "simple" => 0,
      "smooth" => 1,
      "unite_data" => 2,
      "encode" => -1
    }.freeze
  end
end

Graphene.configure do |config|
  # Sidekiq job to send metrics for Siekiq autoscaling
  config.sidekiq_keep_alive = Graphene::JobsTrackingDisabled
  config.sidekiq_tracking = Graphene::JobsTrackingDisabled

  # A Rack middleware to authenticate Graphene API against
  config.auth_middleware = Graphene::NoAuthentication

  config.sidekiq_callbacks_middleware = Graphene::SidekiqCallbacksMiddleware

  # Callback notifier background job delay in seconds
  config.callback_delay = 30 # seconds

  config.callback_auth = {
    method: :https,
    name: :big_sofa_auth,
    credentials: [ENV["LOCATION"], ENV["LOCATION_SECRET"]].freeze,
    class_name: Graphene::NoAuthMiddleware
  }.freeze

  config.poll_timeout = 15 * 60 # 15 minutes

  config.mappings_and_priorities = {
    "default" => DefaultMappingAndPriorities
  }

  # Authentication middleware for the sidekiq UI
  config.sidekiq_auth_middleware = Graphene::NoAuthentication
end
