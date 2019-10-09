# frozen_string_literal: true

ENV["RACK_ENV"] = ENV["RAILS_ENV"] = "test"
ENGINE_RAILS_ROOT = File.join(File.dirname(__FILE__), '../')

require File.expand_path("../../test/dummy/config/environment", __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

FactoryBot.definition_file_paths << File.join(File.dirname(__FILE__), "factories")

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit(1)
end

if ENV["CIRCLE_ARTIFACTS"]
  dir = File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")
  SimpleCov.coverage_dir(dir)
end

[
  "spec/support/jobs/**/*.rb",
  "spec/support/initializers/**/*.rb",
  "spec/support/helpers/**/*.rb",
  "spec/support/shared_contexts/**/*.rb",
  "spec/support/custom_matchers/**/*.rb",
  "spec/**/shared_examples/**/*.rb"
].each do |path|
  Dir[File.expand_path(path)].each do |file|
    require file
  end
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching(:focus)

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This setting enables warnings. It"s recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it"s useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand(config.seed)

  config.include_context(:with_auth_token, :with_auth_token)

  config.include(FactoryBot::Syntax::Methods)
  config.before(:suite) { FactoryBot.find_definitions }
end
