$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "graphene/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "graphene"
  spec.version     = Graphene::VERSION
  spec.authors     = ["BigSofaTech"]
  spec.email       = ["info@bigsofatech.com"]
  spec.homepage    = "https://www.bigsofatech.com/"
  spec.summary     = "Graphene"
  spec.description = "Graphene"
  spec.license     = "BigSofaTech"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md", "Gemfile"]
  s.required_ruby_version = '>= 2.6.0'

  spec.add_dependency "rails", "~> 6.0.0"

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
end
