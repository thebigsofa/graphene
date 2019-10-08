# frozen_string_literal: true

source "https://rubygems.org"

ruby("2.6.3")

# # Bundler no longer treats runtime dependencies as base dependencies.
# # The following code restores this behaviour.
# # (See https://github.com/carlhuda/bundler/issues/1041)
# spec = Bundler.load_gemspec(Dir["./{,*}.gemspec"].first)
# spec.runtime_dependencies.each do |dependency|
#   gem dependency.name, *(dependency.requirement.as_list)
# end

gemspec

gem "sheaf"

gem "pg"
gem "hiredis"

# Job processing
gem "sidekiq-pro", source: "https://gems.contribsys.com/"
gem "sidekiq-throttled"
gem "sidekiq-status"
gem "sidekiq-failures"

# Shellout
gem "terrapin"

# Testing
group :test do
  gem "pry"
  gem "rspec-rails"
  gem "rspec-its"
  gem "rspec_junit_formatter"
  gem "timecop"
  gem "simplecov"
  gem "simplecov-console"
  gem "rubocop"
  gem "warning"
  gem "database_cleaner"
  gem "factory_bot_rails"
end
