# frozen_string_literal: true

RSpec.configure do |config|
  config.append_before do
    Redis.current.flushall
  end
end
