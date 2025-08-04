Rails.application.routes.draw do
  # Authentication routes that bypass API key requirement
  post '/signup', to: 'auth#signup'
  post '/login', to: 'auth#login'
  
  # Simple password reset endpoint (alternative to API namespace)
  post '/password_reset', to: 'auth#password_reset'
  
  # Devise routes (moved to bottom to avoid conflicts)
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  devise_for :clients
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  
  namespace :api do
    namespace :v1 do
      resources :providers, only: [:index, :update, :show, :create] do
        member do
          delete :remove_logo
        end
      end

      namespace :admin do
        resources :providers, only: [:index, :update]
      end

      resources :states, only: [:index] do
        resources :counties, only: [:index]
        resources :providers, only: [:index], action: :index, controller: '/api/v1/states/providers'
      end

      resources :insurances, only: [:index, :create, :update, :destroy]
      
      # User management routes (for Super Admin)
      resources :users, only: [:index, :show, :create] do
        collection do
          post :check_user_exists
          get :debug_lookup
        end
      end
      
      # Password reset routes
      resources :password_resets, only: [:create] do
        collection do
          patch :update
          get :validate_token
        end
      end
      
      # Provider self-editing routes (for logged-in providers)
      resource :provider_self, only: [:show, :update] do
        member do
          delete :remove_logo
        end
      end
    end
  end
end
