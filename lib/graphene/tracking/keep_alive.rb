# frozen_string_literal: true

module Tracking
  class KeepAlive
    include Sidekiq::Worker
    include Sidekiq::Throttled::Worker

    attr_reader :queue
    sidekiq_options(queue: :pipeline_tracking, backtrace: true)

    def perform(queue)
      @queue = queue
      call
    end

    def call
      client.put_metric_data(options)
    end

    private

    def options
      {
        namespace: "Pipeline",
        metric_data: metric_data
      }
    end

    def metric_data
      [
        {
          metric_name: "SidekiqKeepAlive",
          dimensions: dimensions,
          timestamp: Time.zone.now,
          value: 1,
          unit: "Seconds"
        }
      ]
    end

    def aws_location(location)
      mapper = Hash.new(ENV["LOCATION"]).merge!("us-east1" => "us-east-1")
      mapper[location]
    end

    def dimensions
      [
        {
          name: queue,
          value: queue
        }
      ]
    end

    def client
      @client ||= Aws::CloudWatch::Client.new(region: aws_location(ENV["LOCATION"]))
    end
  end
end
