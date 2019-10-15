# frozen_string_literal: true

module Graphene
  def self.table_name_prefix
  end

  class Engine < ::Rails::Engine
    isolate_namespace Graphene

    config.autoload_paths << File.expand_path("../", __dir__)

    # require "graphene/services/cancel_pipeline"
    # require "graphene/services/create_pipeline"
    # require "graphene/services/locked_pipeline"
    # require "graphene/services/update_pipeline"
    require "graphene/serializers/pipeline_serializer"

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    initializer "add_auth_module" do |app|
      app.config.middleware.use Graphene.config.auth_middleware
    end
  end
end
