# frozen_string_literal: true

module Graphene
  class Engine < ::Rails::Engine
    isolate_namespace Graphene
  end
end
