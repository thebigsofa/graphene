# frozen_string_literal: true

module Graphene
  class LocalStorage
    include Singleton

    attr_accessor :data

    def initialize
      @data = {}
    end

    def add(key, value)
      data[key.to_sym] = value
    end

    def get(key)
      data[key.to_sym]
    end
  end
end
