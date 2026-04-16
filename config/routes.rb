Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users, only: :create
      resource :session, only: :create

      resource :balance, only: :show do
        post :deposit
        post :withdraw
      end

      resources :transfers, only: :create
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
