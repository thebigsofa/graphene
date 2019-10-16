# frozen_string_literal: true

module Graphene
  class CallbackAggregate
    attr_accessor :id

    def initialize(pipeline_id:, count: 0)
      @pipeline_id = pipeline_id
      @count = count
    end

    def self.create(pipeline_id:, count: 0)
      new(pipeline_id: pipeline_id, count: count).save
    end

    def increment
      @count = count + 1
      update
      count
    end

    def clear
      @count = 0
      update
      count
    end

    def self.clear(pipeline_id)
      Redis.current.setex(pipeline_id, 24.hours.to_i, 0)
    end

    def save
      Redis.current.setex(@pipeline_id, 24.hours.to_i, @count)
    end
    alias_method :update, :save

    def count
      Redis.current.get(@pipeline_id).to_i
    end

    def self.count_for(pipeline_id)
      Redis.current.get(pipeline_id).to_i
    end

    def find
      Redis.current.get(@pipeline_id)
    end

    def exists?
      find.present?
    end
  end
end
