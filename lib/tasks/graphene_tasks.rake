# frozen_string_literal: true

DEFAULT_GRAPHENE_CONFIG = <<-CONFIG
Graphene.configure do |config|
  # Sidekiq job to send metrics for Siekiq autoscaling
  config.sidekiq_tracker = Graphene::JobsTrackingDisabled

  # A Rack middleware to authenticate Graphene API against
  config.auth_middleware = Graphene::NoAuthentication
end
CONFIG

namespace :graphene do
  namespace :install do
    desc "Create graphene initializer"
    task :config do

      # Step 1: Initializer
      path = Rails.root.join("config/initializers/graphene.rb")

      overwrite = false

      if File.exist?(path)
        puts "Overwrite Graphene configuration? (y/N)"
        overwrite = (STDIN.gets.strip == "y")
      end

      if overwrite || !File.exist?(path)
        File.open(path, "w+") { |file| file.write(DEFAULT_GRAPHENE_CONFIG) }
      end

      puts "Config file created in #{path}"

      # Step 2: Npm packages
      # TODO: add npm dependencies
      # puts "All done. Run `yarn install`"
    end
  end
end
