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
      # Provider assignments (RESTful)
      resources :provider_assignments, only: [:create, :destroy, :index]
      
      # Provider context management
      post "provider_context", to: "provider_context#set"
      get "provider_context", to: "provider_context#show"
      
      resources :providers, only: [:index, :update, :show, :create, :put] do
        collection do
          get :my_providers
          get :accessible_providers
          post :set_active_provider
          post :assign_provider_to_user
          post :remove_provider_from_user
          get :user_providers
        end
        
        member do
          get :locations, to: 'providers#provider_locations'
          post :locations, to: 'providers#add_location'
          patch 'locations/:location_id', to: 'providers#update_location'
          delete 'locations/:location_id', to: 'providers#remove_location'
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
          post :manual_link
          post :switch_provider
          get :unlinked_users
          get :providers_list
          get :users_with_providers
          get :admin_users
          post :bulk_assign_users
          post :assign_user_by_email
          post :unassign_provider_from_user
          post :unlink_user_from_provider
        end
        member do
          post :link_to_provider
          delete :unlink_from_provider
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
      resource :provider_self, only: [:show, :update], controller: 'provider_self' do
        member do
          delete :remove_logo
        end
      end
      
      # Payment routes
      resources :payments, only: [] do
        collection do
          post :create_payment_intent
        end
      end
    end
  end
end
