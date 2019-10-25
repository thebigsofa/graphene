# frozen_string_literal: true

module Graphene
  module Pipelines
    module Config
      class << self
        # TODO: Change this to just the value of params[:mappings_and_priorities]
        def mapping(params)
          mappings_and_priorities(params).mapping
        end

        def priorities(params)
          mappings_and_priorities(params).priorities
        end

        def mappings_and_priorities(params)
          Graphene.config.mappings_and_priorities.fetch(
            params[:mappings_and_priorities] || "default"
          )
        rescue KeyError
          raise "No `#{params[:mappings_and_priorities]}` mappings_and_priorities configuration"
        end
      end
    end
  end
end
