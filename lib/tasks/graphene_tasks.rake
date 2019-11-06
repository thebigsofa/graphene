# frozen_string_literal: true

# rubocop:disable all
DEFAULT_GRAPHENE_CONFIG = <<-CONFIG
ENV["REDIS_URL"] ||= "redis://redis:6379"
ENV["REDIS_DB"] ||= "1"

require "sidekiq"
require "sidekiq/throttled"
require "sidekiq/failures"
require "sidekiq-status"

Sidekiq::Throttled.setup!
Sidekiq::Client.reliable_push! unless Rails.env.test?

Redis.current = Redis.new(db: ENV.fetch("REDIS_DB"))

redis_url = "\#{ENV.fetch("REDIS_URL")}/\#{ENV.fetch("REDIS_DB")}"

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
  config.super_fetch!
  config.reliable_scheduler!
  config.server_middleware do |chain|
    chain.add(Graphene.config.sidekiq_callbacks_middleware)
  end

  config.failures_default_mode = :all
  config.failures_max_count = 1000

  Sidekiq::Status.configure_server_middleware(config, expiration: 1.day)
  Sidekiq::Status.configure_client_middleware(config, expiration: 1.day)
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
  Sidekiq::Status.configure_client_middleware(config, expiration: 1.day)
end

Graphene.configure do |config|
  # Sidekiq jobs to send metrics for Siekiq autoscaling
  config.sidekiq_keep_alive = Graphene::JobsTrackingDisabled
  config.sidekiq_tracking = Graphene::JobsTrackingDisabled
  config.sidekiq_tracker_queue_name = "pipeline_tracking"

  # A Rack middleware to authenticate Graphene API against
  config.auth_middleware = Graphene::NoAuthentication

  config.sidekiq_callbacks_middleware = Graphene::SidekiqCallbacksMiddleware

  # Callback notifier background job delay in seconds
  config.callback_notifier_delay = 30 # seconds

  # Special authentication configuration for callbacks
  config.callback_auth = {
    name: :big_sofa_auth,
    credentials: [].freeze, # eg. ["usernamer", "password"]
    class_name: Graphene::NoAuthMiddleware
  }.freeze

  config.mappings_and_priorities = SampleMapping

  # Authentication middleware for the sidekiq UI
  config.sidekiq_auth_middleware = Graphene::NoAuthentication
end
CONFIG

SAMPLE_MAPPING = <<-SAMPLE_MAPPING
class SampleMapping
  class Task
    include Graphene::Tasks::Task

    def call(data:)
      yield("Inspecting \#{data.inspect}")
    end
  end

  class Job1 < Graphene::Jobs::Base
    STACK = Graphene::Stack[Task]
  end

  class Job2 < Graphene::Jobs::Base
    STACK = Graphene::Stack[Task]
  end

  def self.mapping
    {
      "simple" => [[Job1]],
      "smooth" => [[Job2]]
    }.freeze
  end

  def self.priorities
    {
      "simple" => 0,
      "smooth" => 1
    }.freeze
  end
end
SAMPLE_MAPPING
# rubocop:enable all

namespace :graphene do
  namespace :install do
    desc "Create graphene initializer"
    task :config do
      path = Rails.root.join("config/initializers/graphene.rb")
      mappings_path = Rails.root.join("app/models/sample_mapping.rb")

      overwrite = false

      if File.exist?(path)
        puts "Overwrite Graphene configuration? (y/N)"
        overwrite = (STDIN.gets.strip == "y")
      end

      if overwrite || !File.exist?(path)
        File.open(mappings_path, "w+") { |file| file.write(SAMPLE_MAPPING) }
        File.open(path, "w+") { |file| file.write(DEFAULT_GRAPHENE_CONFIG) }
      end

      puts "Config file created in #{path}"
      puts "Mapping file created in #{mappings_path}"
    end
  end
end
