Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        resources :providers, only: [:index, :update, :show, :create] do
          member do
            delete :remove_logo
          end
        end

        namespace :admin do
          resources :providers, only: [:index]
        end

        resources :states, only: [:index] do
          resources :counties, only: [:index]
          resources :providers, only: [:index], action: :index, controller: '/api/v1/states/providers'
        end

        resources :insurances, only: [:index, :create, :update, :destroy]
      end
    end
  end
end
