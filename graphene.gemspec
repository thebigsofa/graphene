Gem::Specification.new do |s|
  s.name = %q{graphene}
  s.version = "#{Graphene::VERSION}"
  s.date = %q{2011-09-29}
  s.summary = %q{A gem for running pipelines}
  s.files = [
    "lib/graphene.rb"
  ]
  s.require_paths = ["lib"]

  # HTTP
  # s.add_dependency "excon"
  # s.add_dependency "faraday"
  # s.add_dependency "faraday_middleware"

  # Database
  s.add_dependency "pg", ">= 0.18", "< 2.0"
  s.add_dependency "hiredis"

  # Job processing
  s.add_dependency "sidekiq-pro"
  s.add_dependency "sidekiq-throttled"
  s.add_dependency "sidekiq-status"
  s.add_dependency "sidekiq-failures"

  # Shellout
  s.add_dependency "terrapin"

  # Task processing
  s.add_dependency "sheaf"

  # Testing
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rspec_junit_formatter"
  s.add_development_dependency "timecop"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "simplecov-console"
end


