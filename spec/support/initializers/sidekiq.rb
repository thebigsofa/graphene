# frozen_string_literal: true

require "sidekiq/testing"
Sidekiq::Testing.fake!

RSpec.configuration.around :each, delayed_jobs: :inline do |example|
  Sidekiq::Testing.inline!
  example.run
  Sidekiq::Testing.fake!
end

RSpec.configuration.around :each, delayed_jobs: :redis do |example|
  Sidekiq::Testing.disable!
  example.run
  Sidekiq::Testing.fake!
end

RSpec.configure do |config|
  config.append_after do
    Sidekiq::Worker.clear_all
  end
end

Sidekiq.logger = Logger.new(nil)

class SidekiqCallbacksMiddleware
  def call(worker, _msg, queue)
    Graphene::Tracking::SidekiqTrackable.call(queue) unless worker.class == Graphene.config.sidekiq_tracker
    yield
  end
end

Sidekiq::Testing.server_middleware do |chain|
  chain.add(SidekiqCallbacksMiddleware)
end
