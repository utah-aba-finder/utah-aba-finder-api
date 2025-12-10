Rails.application.routes.draw do
  # Authentication routes that bypass API key requirement
  post '/signup', to: 'auth#signup'
  post '/login', to: 'auth#login'
  
  # Simple password reset endpoint (alternative to API namespace)
  post '/password_reset', to: 'auth#password_reset'
  
  # Password change endpoint (requires authentication)
  post '/change_password', to: 'auth#change_password'
  
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
      
      # Provider categories and fields
      resources :provider_categories, only: [:index, :show, :create, :update]
      
      # Provider self-registration workflow
      resources :provider_registrations, only: [:index, :show, :create] do
        member do
          post :approve
          post :reject
        end
      end
      
      resources :providers, only: [:index, :update, :show, :create, :put] do
        collection do
          get :my_providers
          get :accessible_providers
          post :set_active_provider
          post :assign_provider_to_user
          post :remove_provider_from_user
          get :user_providers
          get :view_stats
        end
        
        member do
          get :locations, to: 'providers#provider_locations'
          post :locations, to: 'providers#add_location'
          patch 'locations/:location_id', to: 'providers#update_location'
          delete 'locations/:location_id', to: 'providers#remove_location'
          delete :remove_logo
          post :track_view
        end
      end

      namespace :admin do
        resources :providers, only: [:index, :create, :update]
        resources :users, only: [:index, :show, :update] do
          collection do
            post :assign_providers
          end
        end
        resources :mass_emails, only: [:index] do
          collection do
            post :send_password_reminders
            post :send_system_updates
            get :preview_email
          end
        end
        resources :email_templates, only: [:index, :show, :update] do
          member do
            get :preview
            post :reset
          end
        end
      end

      resources :states, only: [:index] do
        resources :counties, only: [:index]
        resources :providers, only: [:index], action: :index, controller: '/api/v1/states/providers'
      end

      resources :insurances, only: [:index, :create, :update, :destroy] do
        collection do
          get :search
        end
      end
      
      # Practice types
      resources :practice_types, only: [:index]
      
      # Provider categories and registration
      resources :provider_categories, only: [:index, :show, :create, :update]
      resources :provider_registrations, only: [:index, :show, :create] do
        member do
          patch :approve
          patch :reject
        end
      end
      
      # User management routes (for Super Admin)
      resources :users, only: [:index, :show, :create] do
        collection do
          get :users_with_providers
          get :providers_list
          post :bulk_assign_users
        end
        
        member do
          post :unassign_provider_from_user
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
          post :confirm_sponsorship
        end
      end
      
      # Sponsorship routes
      resources :sponsorships, only: [:index, :show, :create, :destroy] do
        collection do
          get :tiers
          get :sponsored_providers
        end
      end
      
      # Stripe webhook
      post 'stripe/webhook', to: 'stripe_webhooks#handle'
      
      # Billing routes
      namespace :billing do
        post :checkout, to: "checkout#create"
      end
    end
  end
end
