# frozen_string_literal: true

module Graphene
  class SidekiqController < ApplicationController
    def queue_data
      render(json: queue_json)
    end

    private

    def queue_json
      {
        queues: queue_array
      }
    end

    # :reek:FeatureEnvy
    def queue_array
      Sidekiq::Queue.all.map do |queue|
        stats = Sidekiq::Queue.new(queue.name)
        {
          name: stats.name,
          size: stats.size,
          latency: stats.latency
        }
      end
    end
  end
end
