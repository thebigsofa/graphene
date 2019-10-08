# frozen_string_literal: true

require "graphene/engine"

module Graphene
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end

  class Config
    attr_accessor :sidekiq_tracker

    def initialize
      @sidekiq_tracker = nil
    end
  end
end
