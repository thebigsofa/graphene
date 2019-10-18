# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Declare your gem's dependencies in graphene.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem "byebug", group: [:development, :test]

gem "sidekiq-pro", source: "https://gems.contribsys.com/"

group :development, :test do
  gem "factory_bot"
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "pry-rails"
  gem "pry-remote"
  gem "rspec-rails", ">= 4.0.0.beta2"
  gem "rspec-its"
  gem "rspec_junit_formatter"
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
end

group :development do
  gem "foreman"
  gem "zencoder-fetcher"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end
