Rails.application.routes.draw do
  mount Graphene::Engine => "/graphene"
end
