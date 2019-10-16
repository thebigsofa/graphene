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

  spec.add_dependency("rails", ">= 6.0.0")

  spec.add_dependency "jquery-rails"
  spec.add_dependency "jquery-ui-rails"
  spec.add_dependency "kaminari"
  spec.add_dependency "bootstrap4-kaminari-views"
  spec.add_dependency "pg_search"

  spec.add_dependency "activerecord_json_validator"

  spec.add_dependency "excon"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"

  spec.add_dependency("pg", ">= 0.18", "< 2.0")
  spec.add_dependency("hiredis")

  # Job processing
  spec.add_dependency("sidekiq-pro")
  spec.add_dependency("sidekiq-throttled")
  spec.add_dependency("sidekiq-status")
  spec.add_dependency("sidekiq-failures")

  spec.add_dependency("sheaf")
end
