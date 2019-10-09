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

gem "jwt"

# HTTP
gem "excon"
gem "faraday"
gem "faraday_middleware"

gem "sheaf"

gem "pg"
gem "pg_search"
gem "hiredis"

gem "activerecord_json_validator"

# Job processing
gem "sidekiq-pro", source: "https://gems.contribsys.com/"
gem "sidekiq-throttled"
gem "sidekiq-status"
gem "sidekiq-failures"

# Shellout
gem "terrapin"

# # Testing
# group :test do
#   gem "pry"
#   gem "rspec-rails"
#   gem "rspec-its"
#   gem "rspec_junit_formatter"
#   gem "timecop"
#   gem "simplecov"
#   gem "simplecov-console"
#   gem "rubocop"
#   gem "warning"
#   gem "database_cleaner"

# end

group :assets do
  gem "sass-rails"
end

group :development, :test do
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "pry-rails"
  gem "pry-remote"
  gem "rspec-rails"
  gem "rspec-its"
  gem "rspec_junit_formatter"
  gem "spring-commands-rspec"
  gem "spring-commands-rubocop"
  gem "spring-commands-sidekiq"
  gem "json_matchers"
  gem "timecop"
  gem "database_cleaner"
  gem "rubocop"
  gem "simplecov"
  gem "simplecov-console"
  gem "warning"
  gem "webmock"
  gem "vcr"
  gem "rswag-specs"
  gem "factory_bot_rails"
end

group :development do
  gem "foreman"
  gem "zencoder-fetcher"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end
