# frozen_string_literal: true

require "webmock/rspec"
require "vcr"

# rubocop:disable Lint/Debugger
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock

  # Usage:
  # VCR.use_cassette("path/to/cassette", match_requests_on: [:debug_request]) do
  #   perform_the_request
  # end
  # It will then stop execution in the line below and let you compare the recorded request
  # with the performed one.
  config.register_request_matcher(:debug_request) do |current_request, recorded_request|
    binding.pry

    true
  end
end
# rubocop:enable Lint/Debugger
