Graphene::Engine.routes.draw do
  require "sidekiq/pro/web"

  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      # Protect against timing attacks:
      # - See https://codahale.com/a-lesson-in-timing-attacks/
      # - See https://thisdata.com/blog/timing-attacks-against-string-comparison/
      # - Use & (do not use &&) so that it doesn't short circuit.
      # - Use digests to stop length information leaking (see also ActiveSupport::SecurityUtils.variable_size_secure_compare)
      # ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_USERNAME"])) &
      #   ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["SIDEKIQ_PASSWORD"]))

      Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(username), ENV["SIDEKIQ_USERNAME"]) &
        Rack::Utils.secure_compare(::Digest::SHA256.hexdigest(password), ENV["SIDEKIQ_PASSWORD"])
    end
  end
  mount Sidekiq::Web, at: "/sidekiq"

  resources :pipelines, only: [:create, :show, :update] do
    member { get :locked }
    member { put :cancel }
  end

  namespace :sidekiq do
    get :queue_data
  end

  namespace :ui do
    resources :pipelines, only: [:index, :show]
  end

  get "/status" => "service_status#show"
end
