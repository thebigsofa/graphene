Graphene::Engine.routes.draw do
  require "sidekiq/pro/web"
  require "sidekiq-status/web"

  Sidekiq::Web.use Graphene.config.sidekiq_auth_middleware
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

  get "/status" => "service_status#status"

  root "service_status#status"
end
