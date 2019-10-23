# frozen_string_literal: true

module Graphene
  def self.table_name_prefix
  end

  class Engine < ::Rails::Engine
    isolate_namespace Graphene

    initializer :append_migrations do |app|
      unless app.root.to_s.match(root.to_s)
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "add_auth_module" do |app|
      app.config.middleware.use Graphene.config.auth_middleware
    end
  end
end
