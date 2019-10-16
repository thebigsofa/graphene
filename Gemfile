# frozen_string_literal: true

source "https://rubygems.org"

ruby("2.6.3")

# Bundler no longer treats runtime dependencies as base dependencies.
# The following code restores this behaviour.
# (See https://github.com/carlhuda/bundler/issues/1041)
spec = Bundler.load_gemspec(Dir["./{,*}.gemspec"].first)
spec.runtime_dependencies.each do |dependency|
  gem dependency.name, *(dependency.requirement.as_list)
end

gemspec

gem "sidekiq-pro", source: "https://gems.contribsys.com/"

# Testing
group :test do
  gem "rspec-rails"
  gem "rspec-its"
  gem "rspec_junit_formatter"
  gem "timecop"
  gem "simplecov"
  gem "simplecov-console"
  gem "rubocop"
  gem "warning"
  gem "database_cleaner"
  gem "factory_bot"
end
