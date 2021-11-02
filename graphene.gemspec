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

  # # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]

  spec.add_dependency("rails", "~> 6.0.0")

  spec.add_dependency("jquery-rails", "~> 4.3.5")
  spec.add_dependency("jquery-ui-rails", "~> 6.0.1")
  spec.add_dependency("kaminari", "~> 1.1.1")
  spec.add_dependency("bootstrap4-kaminari-views", "~> 1.0.1")
  spec.add_dependency("pg_search", "~> 2.3.0")
  spec.add_dependency("ruby-kafka")

  spec.add_dependency("activerecord_json_validator", "~> 1.3.0")

  spec.add_dependency("excon", "~> 0.67.0")
  spec.add_dependency("faraday", "~> 1.0")
  spec.add_dependency("faraday_middleware")

  spec.add_dependency("pg", "~> 1.1.4")

  spec.add_dependency("hiredis", "~> 0.6.3")

  # Job processing
  spec.add_dependency("sidekiq-pro", "~> 5.0.1")
  spec.add_dependency("sidekiq-throttled", "~> 0.11.0")
  spec.add_dependency("sidekiq-status", "~> 1.1.4")
  spec.add_dependency("sidekiq-failures", "~> 1.0.0")

  spec.add_dependency("sheaf", "~> 0.1.1")
end
