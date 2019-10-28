# frozen_string_literal: true

module Graphene
  module Graph
    class Config
      class << self
        def call(config_name)
          Graphene.config.mappings_and_priorities.fetch(config_name || "default")
        rescue KeyError
          raise "No `#{config_name}` mappings_and_priorities configuration"
        end
      end
    end
  end
end
