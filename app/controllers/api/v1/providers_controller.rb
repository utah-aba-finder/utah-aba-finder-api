class Api::V1::ProvidersController < ApplicationController
  skip_before_action :authenticate_client, only: [:show, :update, :put, :remove_logo, :claim_account]

  before_action :authenticate_provider_or_client, only: [:show, :update, :put, :remove_logo]
  before_action :authenticate_user!, only: [:accessible_providers, :set_active_provider]
  
  # IMPORTANT: skip client auth for actions that use authenticate_provider_or_client
  skip_before_action :authenticate_client, only: [:index, :accessible_providers, :set_active_provider, :show, :update, :put, :remove_logo, :claim_account]

  def index
    puts "🔍 Controller loaded: #{__FILE__}"
    puts "🔍 Actions: #{self.class.action_methods.to_a.sort.join(', ')}"
    
    # Start with approved providers
    providers = Provider.where(status: :approved)
    
    # Filter by provider type if specified
    if params[:provider_type].present?
      # Try to find by practice_types first (new system)
      practice_type_providers = providers.joins(:practice_types)
                                        .where(practice_types: { name: params[:provider_type] })
                                        .distinct
      
      # Also try to find by category field (legacy system)
      category_providers = providers.where(category: params[:provider_type].downcase.gsub(' ', '_'))
      
      # Combine both results
      provider_ids = (practice_type_providers.pluck(:id) + category_providers.pluck(:id)).uniq
      providers = providers.where(id: provider_ids)
    end
    
    # Filter by state if specified
    if params[:state].present?
      # Find the state by name or abbreviation
      state = State.find_by("LOWER(name) = ? OR LOWER(abbreviation) = ?", 
                           params[:state].downcase, params[:state].downcase)
      
      if state
        # Get providers that serve this state through:
        # 1. Counties (for in-home services)
        # 2. Locations (for clinic-based services)
        county_provider_ids = providers.joins(counties: :state)
                                      .where(counties: { state_id: state.id })
                                      .distinct
                                      .pluck(:id)
        
        location_provider_ids = providers.joins(:locations)
                                       .where(locations: { state: state.abbreviation })
                                       .distinct
                                       .pluck(:id)
        
        # Combine both sets of provider IDs
        provider_ids = (county_provider_ids + location_provider_ids).uniq
        providers = providers.where(id: provider_ids)
      end
    end
    
    # Filter by state_id if specified (alternative to state name)
    if params[:state_id].present?
      state = State.find_by(id: params[:state_id])
      if state
        # Get providers that serve this state through counties or locations
        county_provider_ids = providers.joins(counties: :state)
                                      .where(counties: { state_id: state.id })
                                      .distinct
                                      .pluck(:id)
        
        location_provider_ids = providers.joins(:locations)
                                       .where(locations: { state: state.abbreviation })
                                       .distinct
                                       .pluck(:id)
        
        # Combine both sets of provider IDs
        provider_ids = (county_provider_ids + location_provider_ids).uniq
        providers = providers.where(id: provider_ids)
      end
    end
    
    # Include necessary associations for performance
    # Note: counties must include state to avoid N+1 in serializer
    includes_array = [
      { counties: :state },  # Include state to avoid N+1 in get_provider_states
      :practice_types, 
      { locations: :practice_types },
      { provider_insurances: :insurance },
      :insurances
    ]
    includes_array += [:logo_attachment, :logo_blob] unless Rails.env.test?
    providers = providers.includes(includes_array)
    
    # Order providers: sponsored first (by tier), then non-sponsored
    # Tier priority: partner (3) > sponsor (2) > featured (1) > free (0)
    # Use DESC ordering so higher tier numbers come first
    providers = providers.order(sponsorship_tier: :desc, name: :asc)
    
    render json: ProviderSerializer.format_providers(providers)
  end

  def create
    provider = Provider.new(provider_params)
    if provider.save
      provider.initialize_provider_insurances
      # should create methods in provider model to handle extra creation/association logic
      params[:data].first[:attributes][:locations].each do |location|
        provider.locations.create!(
          name: location[:name],
          address_1: location[:address_1] ,
          address_2: location[:address_2] ,
          city: location[:city] ,
          state: location[:state] ,
          zip: location[:zip] ,
          phone: location[:phone] 
        )
      end
      # provider.old_counties.create!(counties_served: params[:data].first[:attributes][:counties_served])
      # Update counties (new logic)
      provider.update_counties_from_array(params[:data].first[:attributes][:counties_served].map { |county| county["county_id"] })

      params[:data].first[:attributes][:insurance].each do |insurance|
        insurance_found = Insurance.find(insurance[:id])
        provider_insurance = ProviderInsurance.find_by(provider_id: provider.id, insurance_id: insurance_found.id)
        provider_insurance.update!(accepted: true) if provider_insurance
      end

      provider.create_practice_types(params[:data].first[:attributes][:provider_type])

      render json: ProviderSerializer.format_providers([provider])
    else
      render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    provider = Provider.find(params[:id])
    
    Rails.logger.info "🔍 Update method - @current_user: #{@current_user&.id}"
    Rails.logger.info "🔍 Update method - @current_client: #{@current_client&.id}"
    Rails.logger.info "🔍 Update method - Provider ID: #{provider.id}"
    Rails.logger.info "🔍 Update method - Provider user_id: #{provider.user_id}"
    
    # Check if current user can access this provider (for user authentication)
    if @current_user && !@current_user.can_access_provider?(provider.id)
      Rails.logger.info "🔍 Update method - Access denied for user #{@current_user.id}"
      render json: { error: 'Access denied. You can only update providers you have access to.' }, status: :forbidden
      return
    end
    
    # For API key authentication (@current_client), allow access (legacy behavior)
    # @current_client is set by authenticate_provider_or_client when using API key

    Rails.logger.info "Content-Type: #{request.content_type}"
    Rails.logger.info "Logo present: #{params[:logo].present?}"
    Rails.logger.info "Multipart condition: #{request.content_type&.include?('multipart/form-data') || params[:logo].present?}"

    if request.content_type&.include?('multipart/form-data') || params[:logo].present?
      Rails.logger.info "Using multipart path"
      # Handle multipart form data (for logo uploads)
      provider.assign_attributes(multipart_provider_params)
      
          # Handle logo upload using Active Storage
    if params[:logo].present?
      Rails.logger.info "Logo file received: #{params[:logo].original_filename}"
      Rails.logger.info "Params logo content type: #{params[:logo].content_type}"
      Rails.logger.info "Params logo original filename: #{params[:logo].original_filename}"
      Rails.logger.info "Params logo content length: #{params[:logo].size}"
      Rails.logger.info "Active Storage attached before?: #{provider.logo.attached?}"
      
      # Attach the logo file to Active Storage
      provider.logo.attach(params[:logo])
      
      Rails.logger.info "Active Storage attached after?: #{provider.logo.attached?}"
    end
      
      # Ensure required fields are preserved if not provided
      provider.in_home_only = provider.in_home_only unless params[:in_home_only].present?
      provider.service_delivery = provider.service_delivery unless params[:service_delivery].present?
      
      if provider.save
        provider.touch
        logo_info = provider.logo.attached? ? "Logo attached: #{provider.logo.filename}" : "No logo attached"
        Rails.logger.info "Provider saved successfully. #{logo_info}"
        render json: ProviderSerializer.format_providers([provider])
      else
        Rails.logger.error "Provider save failed: #{provider.errors.full_messages}"
        render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
      end
    else
      Rails.logger.info "Using JSON path"
      # Handle JSON data (for regular updates)
      if provider.update(provider_params)
        # Get the attributes from either array or hash structure
        attributes = if params[:data].is_a?(Array) && params[:data].first&.dig(:attributes)
          params[:data].first[:attributes]
        elsif params[:data]&.dig(:attributes)
          params[:data][:attributes]
        else
          {}
        end
        
        # Only update locations if locations data is provided
        if attributes[:locations]&.present?
          provider.update_locations(attributes[:locations])
        end
        
        # Only update insurance if insurance data is provided
        if attributes[:insurance]&.present?
          provider.update_provider_insurance(attributes[:insurance])
        end
        
        # Only update counties if counties data is provided
        if attributes[:counties_served]&.present?
          provider.update_counties_from_array(attributes[:counties_served].map { |county| county["county_id"] })
        end
        
        # Only update practice types if practice type data is provided
        if attributes[:provider_type]&.present?
          provider.update_practice_types(attributes[:provider_type])
        end
        
        provider.touch # Ensure updated_at is updated
        render json: ProviderSerializer.format_providers([provider])
      else
        render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end

  def put
    # PUT method for provider self logo upload (same as update but specifically for logo)
    provider = Provider.find(params[:id])
    
    # Check if current user can access this provider (for user authentication)
    if @current_user && !@current_user.can_access_provider?(provider.id)
      render json: { error: 'Access denied. You can only update providers you have access to.' }, status: :forbidden
      return
    end
    
    # For API key authentication (@current_client), allow access (legacy behavior)
    # @current_client is set by authenticate_provider_or_client when using API key
    
    Rails.logger.info "PUT method - Content-Type: #{request.content_type}"
    Rails.logger.info "PUT method - Logo present: #{params[:logo].present?}"
    
    if request.content_type&.include?('multipart/form-data') || params[:logo].present?
      Rails.logger.info "PUT method - Using multipart path"
      # Handle multipart form data (for logo uploads)
      provider.assign_attributes(multipart_provider_params)
      
      # Handle logo upload using Active Storage
      if params[:logo].present?
        Rails.logger.info "PUT method - Logo file received: #{params[:logo].original_filename}"
        provider.logo.attach(params[:logo])
      end
      
      if provider.save
        provider.touch
        Rails.logger.info "PUT method - Provider saved successfully"
        render json: ProviderSerializer.format_providers([provider])
      else
        Rails.logger.error "PUT method - Provider save failed: #{provider.errors.full_messages}"
        render json: { errors: provider.errors.full_messages }, status: :unprocessable_entity
      end
    else
      Rails.logger.info "PUT method - No logo provided"
      render json: { error: 'No logo file provided' }, status: :unprocessable_entity
    end
  end

  def remove_logo
    provider = Provider.find(params[:id])
    
    # Check if current user can access this provider (for user authentication)
    if @current_user && !@current_user.can_access_provider?(provider.id)
      render json: { error: 'Access denied. You can only update providers you have access to.' }, status: :forbidden
      return
    end
    
    # For API key authentication (@current_client), allow access (legacy behavior)
    # @current_client is set by authenticate_provider_or_client when using API key
    provider.remove_logo
    provider.touch # Update the timestamp
    render json: { message: 'Logo removed successfully' }
  end

  def show
    provider = Provider.includes(
      :practice_types,
      { :locations => :practice_types },
      { :provider_insurances => :insurance },
      { :provider_attributes => :category_field },
      { :provider_category => :category_fields },
      :counties
    ).find(params[:id])
    render json: ProviderSerializer.format_providers([provider])
  end

  # Multi-provider management methods
  def my_providers
    # Try to authenticate as user first, then fall back to API key auth
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    if token.present?
      # Try user authentication first
      user = User.find_by(id: token)
      if user
        @current_user = user
      else
        # If no user found, try API key authentication
        client = Client.find_by(api_key: token)
        unless client
          render json: { error: 'Invalid authorization token' }, status: :unauthorized
          return
        end
        @current_client = client
        render json: { error: 'API key authentication not supported for this endpoint' }, status: :unauthorized
        return
      end
    else
      render json: { error: 'No authorization token provided' }, status: :unauthorized
      return
    end
    
    if @current_user
      # Get all providers this user can manage (both legacy and new relationships)
      providers = @current_user.all_managed_providers
      render json: ProviderSerializer.format_providers(providers)
    else
      render json: { error: 'User not authenticated' }, status: :unauthorized
    end
  end

  def accessible_providers
    # Try to authenticate as user first, then fall back to API key auth
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    if token.present?
      # Try user authentication first
      user = User.find_by(id: token)
      if user
        @current_user = user
      else
        # If no user found, try API key authentication
        client = Client.find_by(api_key: token)
        unless client
          render json: { error: 'Invalid authorization token' }, status: :unauthorized
          return
        end
        @current_client = client
        render json: { error: 'API key authentication not supported for this endpoint' }, status: :unauthorized
        return
      end
    else
      render json: { error: 'No authorization token provided' }, status: :unauthorized
      return
    end
    
    if @current_user
      all_providers = @current_user.all_managed_providers
      current_provider = @current_user.active_provider
      
      render json: {
        providers: ProviderSerializer.format_providers(all_providers),
        current_provider_id: current_provider&.id,
        total_count: all_providers.count
      }
    else
      render json: { error: 'User not authenticated' }, status: :unauthorized
    end
  end

  def set_active_provider
    # Try to authenticate as user first
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    if token.present?
      user = User.find_by(id: token)
      if user
        provider_id = params.require(:provider_id)
        
        unless user.can_access_provider?(provider_id)
          render json: { error: "Forbidden - You don't have access to this provider" }, status: :forbidden
          return
        end
        
        if user.set_active_provider(provider_id)
          render json: { 
            success: true,
            active_provider_id: provider_id,
            message: "Active provider context updated"
          }
        else
          render json: { error: "Failed to set active provider" }, status: :unprocessable_entity
        end
        return
      end
    end
    
    # If user authentication fails, return unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  # Assign a user to a provider (for admin operations)
  def assign_provider_to_user
    user_email = params[:user_email]
    provider_id = params[:provider_id]
    
    if user_email.blank? || provider_id.blank?
      render json: { error: "Both user_email and provider_id are required" }, status: :bad_request
      return
    end
    
    begin
      user = User.find_by(email: user_email)
      provider = Provider.find(provider_id)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      # Check if user already has access to this provider (either as primary or assigned)
      if user.can_access_provider?(provider_id)
        render json: { 
          error: "User #{user_email} already has access to provider #{provider.name}",
          user: { id: user.id, email: user.email, provider_id: user.provider_id },
          provider: { id: provider.id, name: provider.name },
          access_type: user.primary_owner_of?(provider) ? "primary_owner" : "assigned"
        }, status: :conflict
        return
      end
      
      # Create a provider assignment (adds to user's provider list)
      assignment = ProviderAssignment.create!(
        user: user,
        provider: provider,
        assigned_by: current_user&.email || user.email # Track who made the assignment
      )
      
      render json: { 
        success: true,
        message: "User successfully assigned to provider",
        assignment: {
          id: assignment.id,
          user_id: user.id,
          provider_id: provider.id,
          assigned_by: assignment.assigned_by
        },
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          provider_id: user.provider_id, # Primary provider (unchanged)
          accessible_providers_count: user.all_managed_providers.count
        },
        provider: {
          id: provider.id,
          name: provider.name,
          email: provider.email
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # List all providers a user can access (including assignments)
  def user_providers
    user_email = params[:user_email]
    
    if user_email.blank?
      render json: { error: "user_email is required" }, status: :bad_request
      return
    end
    
    begin
      user = User.find_by(email: user_email)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      # Get all providers user can access
      accessible_providers = user.all_managed_providers
      
      render json: {
        success: true,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          primary_provider_id: user.provider_id,
          active_provider_id: user.active_provider_id
        },
        providers: accessible_providers.map do |provider|
          {
            id: provider.id,
            name: provider.name,
            email: provider.email,
            status: provider.status,
            access_type: user.primary_owner_of?(provider) ? "primary_owner" : "assigned",
            is_active: provider.id == user.active_provider_id
          }
        end,
        total_count: accessible_providers.count
      }, status: :ok
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Remove a user's access to a provider (for admin operations)
  def remove_provider_from_user
    user_email = params[:user_email]
    provider_id = params[:provider_id]
    
    if user_email.blank? || provider_id.blank?
      render json: { error: "Both user_email and provider_id are required" }, status: :bad_request
      return
    end
    
    begin
      user = User.find_by(email: user_email)
      provider = Provider.find(provider_id)
      
      if user.nil?
        render json: { error: "User not found with email: #{user_email}" }, status: :not_found
        return
      end
      
      # Check if user is the primary owner (can't remove primary ownership)
      if user.primary_owner_of?(provider)
        render json: { 
          error: "Cannot remove primary ownership. User #{user_email} is the primary owner of provider #{provider.name}",
          user: { id: user.id, email: user.email, provider_id: user.provider_id },
          provider: { id: provider.id, name: provider.name }
        }, status: :forbidden
        return
      end
      
      # Find and remove the assignment
      assignment = user.provider_assignments.find_by(provider: provider)
      
      if assignment.nil?
        render json: { 
          error: "User #{user_email} does not have an assignment to provider #{provider.name}",
          user: { id: user.id, email: user.email },
          provider: { id: provider.id, name: provider.name }
        }, status: :not_found
        return
      end
      
      assignment.destroy!
      
      render json: { 
        success: true,
        message: "User access to provider removed successfully",
        user: {
          id: user.id,
          email: user.email,
          accessible_providers_count: user.all_managed_providers.count
        },
        provider: {
          id: provider.id,
          name: provider.name
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Provider not found with ID: #{provider_id}" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Claim account endpoint - creates a claim request that requires super admin approval
  # Supports two methods:
  # 1. Direct email match (if email matches provider's registered email) - still requires approval
  # 2. Provider name + claimer email - requires approval
  def claim_account
    email = params[:email]
    provider_name = params[:provider_name]
    provider_id = params[:provider_id]
    claimer_email = params[:claimer_email] || email
    
    if claimer_email.blank?
      render json: { 
        error: "claimer_email is required",
        suggestion: "Please provide the email address you want to use for your account"
      }, status: :bad_request
      return
    end
    
    begin
      provider = nil
      
      # Find provider by ID, name, or email
      if provider_id.present?
        provider = Provider.find_by(id: provider_id, status: :approved)
      elsif provider_name.present?
        providers = Provider.where("LOWER(name) ILIKE ?", "%#{provider_name.downcase}%")
                           .where(status: :approved)
        
        if providers.count > 1
          render json: {
            error: "Multiple providers found",
            message: "Please specify which provider you want to claim. Found #{providers.count} providers:",
            providers: providers.map do |p|
              {
                id: p.id,
                name: p.name,
                email: p.email,
                website: p.website
              }
            end,
            suggestion: "Please provide provider_id to specify which provider"
          }, status: :multiple_choices
          return
        elsif providers.count == 1
          provider = providers.first
        end
      elsif email.present?
        # Try to find by email match first
        providers = Provider.where("LOWER(email) = ?", email.downcase).where(status: :approved)
        provider = providers.first if providers.count == 1
      end
      
      if provider.nil?
        render json: { 
          error: "No provider account found",
          suggestion: "Please provide provider_id, provider_name, or ensure your email matches the provider's registered email"
        }, status: :not_found
        return
      end
      
      # Check if user already has access
      existing_user = User.find_by(email: claimer_email.downcase)
      if existing_user && existing_user.all_managed_providers.where(id: provider.id).exists?
        render json: {
          success: true,
          message: "You already have access to this provider account",
          user: {
            id: existing_user.id,
            email: existing_user.email,
            role: existing_user.role
          },
          provider: {
            id: provider.id,
            name: provider.name,
            email: provider.email
          }
        }, status: :ok
        return
      end
      
      # Check if there's already a pending claim request
      existing_request = ProviderClaimRequest.pending
                                            .where(provider: provider, claimer_email: claimer_email.downcase)
                                            .first
      
      if existing_request
        render json: {
          success: true,
          message: "A claim request is already pending for this provider. Please wait for admin approval.",
          claim_request: {
            id: existing_request.id,
            status: existing_request.status,
            created_at: existing_request.created_at
          }
        }, status: :ok
        return
      end
      
      # Create claim request
      Rails.logger.info "Creating claim request for provider ID: #{provider.id}, name: #{provider.name}, claimer: #{claimer_email}"
      claim_request = ProviderClaimRequest.create!(
        provider: provider,
        claimer_email: claimer_email.downcase
      )
      
      # Reload to ensure associations are loaded
      claim_request.reload
      Rails.logger.info "Claim request created: ID #{claim_request.id}, Provider ID: #{claim_request.provider_id}, Provider loaded: #{claim_request.provider.present?}"
      
      # Send confirmation email to claimer
      ProviderClaimMailer.claim_submitted(claim_request).deliver_later
      
      # Send notification email to admin
      AdminNotificationMailer.new_provider_claim_request(claim_request).deliver_later
      
      render json: {
        success: true,
        message: "Claim request submitted successfully. Your request will be reviewed by an administrator. You will receive an email once it's been approved.",
        claim_request: {
          id: claim_request.id,
          status: claim_request.status,
          provider: {
            id: provider.id,
            name: provider.name,
            email: provider.email
          },
          claimer_email: claim_request.claimer_email,
          created_at: claim_request.created_at
        }
      }, status: :created
      
    rescue => e
      Rails.logger.error "Error in claim_account: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred while submitting claim request: #{e.message}" }, status: :internal_server_error
    end
  end
  

  # Location Management Methods
  # Get all locations for a provider
  def provider_locations
    provider_id = params[:id]
    
    begin
      provider = Provider.find(provider_id)
      locations = provider.locations
      
      render json: {
        success: true,
        provider: {
          id: provider.id,
          name: provider.name
        },
        locations: locations.map do |location|
          {
            id: location.id,
            name: location.name,
            phone: location.phone,
            email: location.email,
            address_1: location.address_1,
            address_2: location.address_2,
            city: location.city,
            state: location.state,
            zip: location.zip,
            in_home_waitlist: location.in_home_waitlist,
            in_clinic_waitlist: location.in_clinic_waitlist,
            practice_types: location.practice_types.pluck(:name)
          }
        end,
        total_count: locations.count
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Provider not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Add a new location to a provider
  def add_location
    provider_id = params[:id]
    
    begin
      provider = Provider.find(provider_id)
      
      location = provider.locations.build(location_params)
      
      if location.save
        render json: {
          success: true,
          message: "Location added successfully",
          location: {
            id: location.id,
            name: location.name,
            phone: location.phone,
            email: location.email,
            address_1: location.address_1,
            address_2: location.address_2,
            city: location.city,
            state: location.state,
            zip: location.zip,
            in_home_waitlist: location.in_home_waitlist,
            in_clinic_waitlist: location.in_clinic_waitlist
          }
        }, status: :created
      else
        render json: { 
          error: "Failed to create location",
          errors: location.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Provider not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Update a location
  def update_location
    provider_id = params[:id]
    location_id = params[:location_id]
    
    begin
      provider = Provider.find(provider_id)
      location = provider.locations.find(location_id)
      
      if location.update(location_params)
        render json: {
          success: true,
          message: "Location updated successfully",
          location: {
            id: location.id,
            name: location.name,
            phone: location.phone,
            email: location.email,
            address_1: location.address_1,
            address_2: location.address_2,
            city: location.city,
            state: location.state,
            zip: location.zip,
            in_home_waitlist: location.in_home_waitlist,
            in_clinic_waitlist: location.in_clinic_waitlist
          }
        }
      else
        render json: { 
          error: "Failed to update location",
          errors: location.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Provider or location not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Remove a location from a provider
  def remove_location
    provider_id = params[:id]
    location_id = params[:location_id]
    
    begin
      provider = Provider.find(provider_id)
      location = provider.locations.find(location_id)
      
      location_name = location.name.presence || "Location #{location.id}"
      location.destroy!
      
      render json: {
        success: true,
        message: "Location '#{location_name}' removed successfully"
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Provider or location not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # Track a provider view (called when ProviderModal opens)
  def track_view
    provider = Provider.find(params[:id])
    fp = fingerprint(request)
    
    ProviderView.find_or_create_by!(
      provider: provider,
      fingerprint: fp,
      view_date: Date.current
    )
    
    head :ok
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Provider not found" }, status: :not_found
  rescue ActiveRecord::RecordNotUnique
    # Already tracked for this fingerprint today, that's fine
    head :ok
  rescue => e
    Rails.logger.error "Error tracking view: #{e.message}"
    head :ok # Fail silently to avoid breaking frontend
  end

  # Get view statistics for a provider
  # Available to all sponsored tiers with different access levels:
  # - Featured: Basic (total views this month)
  # - Sponsor: Standard (30-day views, trend chart, clicks to website)
  # - Partner: Full (daily stats, 90-day history, referral sources, geographic insights)
  def view_stats
    # Authenticate user to get their providers
    token = request.headers['Authorization']&.gsub('Bearer ', '')
    
    if token.present?
      user = User.find_by(id: token)
      if user
        @current_user = user
      else
        render json: { error: 'Invalid authorization token' }, status: :unauthorized
        return
      end
    else
      render json: { error: 'No authorization token provided' }, status: :unauthorized
      return
    end
    
    # Get provider from params or use active provider
    provider_id = params[:provider_id] || @current_user.active_provider&.id
    
    unless provider_id
      render json: { error: 'Provider ID is required or set an active provider' }, status: :bad_request
      return
    end
    
    provider = Provider.find(provider_id)
    
    # Check access
    unless @current_user.can_access_provider?(provider.id)
      render json: { error: 'Access denied' }, status: :forbidden
      return
    end
    
    # Check if provider has an active sponsorship
    # Return success response with message instead of error to avoid logging users out
    unless provider.is_sponsored? && provider.sponsored_until && provider.sponsored_until > Time.current
      render json: { 
        message: 'No active subscription found. View statistics are only available to sponsored providers.',
        has_subscription: false,
        requires_sponsorship: true,
        current_tier: provider.sponsorship_tier,
        subscription_status: provider.is_sponsored? ? 'expired' : 'none',
        sponsored_until: provider.sponsored_until,
        upgrade_message: 'Please upgrade to a sponsored tier to access view statistics and analytics.',
        tiers_url: '/api/v1/sponsorships/tiers'
      }, status: :ok
      return
    end
    
    # Determine analytics level based on tier
    analytics_level = case provider.sponsorship_tier_before_type_cast
                      when 1 # featured
                        'basic'
                      when 2 # sponsor
                        'standard'
                      when 3 # partner
                        'full'
                      else
                        render json: { 
                          message: 'No active subscription found. View statistics are only available to sponsored providers.',
                          has_subscription: false,
                          requires_sponsorship: true,
                          current_tier: provider.sponsorship_tier,
                          subscription_status: 'none',
                          upgrade_message: 'Please upgrade to a sponsored tier to access view statistics and analytics.',
                          tiers_url: '/api/v1/sponsorships/tiers'
                        }, status: :ok
                        return
                      end
    
    # Calculate date ranges based on tier
    current_month_start = Date.current.beginning_of_month
    case analytics_level
    when 'basic'
      # Featured: Total views this month only
      start_date = current_month_start
      end_date = Date.current
      days_requested = nil
    when 'standard'
      # Sponsor: 30-day views
      start_date = Date.current - 30.days
      end_date = Date.current
      days_requested = 30
    when 'full'
      # Partner: Up to 90-day history (default 30, can request up to 90)
      max_days = 90
      requested_days = [(params[:days] || 30).to_i, max_days].min
      start_date = Date.current - requested_days.days
      end_date = Date.current
      days_requested = requested_days
    end
    
    # Get view data
    views = ProviderView.where(provider: provider, view_date: start_date..end_date)
    
    # Build response based on analytics level
    response = {
      has_subscription: true,
      analytics_level: analytics_level,
      tier: case provider.sponsorship_tier_before_type_cast
            when 1 then 'featured'
            when 2 then 'sponsor'
            when 3 then 'partner'
            else 'free'
            end,
      start_date: start_date,
      end_date: end_date
    }
    
    case analytics_level
    when 'basic'
      # Basic: Just total views this month
      total_views = views.count
      response.merge!({
        total_views: total_views,
        period: 'this_month'
      })
    when 'standard'
      # Standard: 30-day views, trend chart data
      by_day = views.group(:view_date).count
      total_views = views.count
      
      # Calculate trend (comparing first half vs second half of period)
      days_diff = (end_date - start_date).to_i
      midpoint = start_date + (days_diff / 2).days
      first_half = views.where(view_date: start_date..midpoint).count
      second_half = views.where(view_date: (midpoint + 1.day)..end_date).count
      trend = second_half > first_half ? 'up' : (second_half < first_half ? 'down' : 'stable')
      trend_percentage = first_half > 0 ? ((second_half - first_half).to_f / first_half * 100).round(1) : 0
      
      response.merge!({
        by_day: by_day,
        total_views: total_views,
        trend: trend,
        trend_percentage: trend_percentage,
        clicks_to_website: 0 # TODO: Implement website click tracking
      })
    when 'full'
      # Full: Daily stats, extended history, referral sources, geographic insights
      by_day = views.group(:view_date).count
      total_views = views.count
      
      # Calculate trend
      days_diff = (end_date - start_date).to_i
      midpoint = start_date + (days_diff / 2).days
      first_half = views.where(view_date: start_date..midpoint).count
      second_half = views.where(view_date: (midpoint + 1.day)..end_date).count
      trend = second_half > first_half ? 'up' : (second_half < first_half ? 'down' : 'stable')
      trend_percentage = first_half > 0 ? ((second_half - first_half).to_f / first_half * 100).round(1) : 0
      
      response.merge!({
        by_day: by_day,
        total_views: total_views,
        days_requested: days_requested,
        trend: trend,
        trend_percentage: trend_percentage,
        clicks_to_website: 0, # TODO: Implement website click tracking
        referral_sources: {}, # TODO: Implement referral source tracking
        geographic_insights: {} # TODO: Implement geographic insights tracking
      })
    end
    
    render json: response
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Provider not found" }, status: :not_found
  rescue => e
    Rails.logger.error "Error getting view stats: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def fingerprint(req)
    raw = [
      req.remote_ip.to_s,
      req.user_agent.to_s[0..100], # truncate to keep short
      Date.current.to_s
    ].join("|")
    Digest::SHA256.hexdigest(raw)
  end
  
  def multipart_provider_params
    params.permit(
      :name,
      :website,
      :email,
      :cost,
      :min_age,
      :max_age,
      :waitlist,
      :telehealth_services,
      :spanish_speakers,
      :at_home_services,
      :in_clinic_services,
      :status,
      :provider_type,
      :in_home_only,
      :logo,
      service_delivery: {}
    )
  end

  def location_params
    params.require(:location).permit(
      :name,
      :phone,
      :email,
      :address_1,
      :address_2,
      :city,
      :state,
      :zip,
      :in_home_waitlist,
      :in_clinic_waitlist
    )
  end

  def provider_params
    # Handle both array and hash structures for data
    if params[:data].present?
      if params[:data].is_a?(Array) && params[:data].first&.dig(:attributes)
        # Handle array structure (like in tests)
        params[:data].first[:attributes].permit(
          :name,
          :website,
          :email,
          :cost,
          :min_age,
          :max_age,
          :waitlist,
          :telehealth_services,
          :spanish_speakers,
          :at_home_services,
          :in_clinic_services,
          :status,
          :provider_type,
          :in_home_only,
          :logo,  # Changed from logo: [] to :logo to accept single file
          service_delivery: {}
        )
      elsif params[:data]&.dig(:attributes)
        # Handle hash structure (like in actual API calls)
        params[:data][:attributes].permit(
          :name,
          :website,
          :email,
          :cost,
          :min_age,
          :max_age,
          :waitlist,
          :telehealth_services,
          :spanish_speakers,
          :at_home_services,
          :in_clinic_services,
          :status,
          :provider_type,
          :in_home_only,
          :logo,  # Changed from logo: [] to :logo to accept single file
          service_delivery: {}
        )
      else
        # Fallback for simple updates
        params.permit(
          :name,
          :website,
          :email,
          :cost,
          :min_age,
          :max_age,
          :waitlist,
          :telehealth_services,
          :spanish_speakers,
          :at_home_services,
          :in_clinic_services,
          :status,
          :provider_type,
          :in_home_only,
          :logo,  # Changed from logo: [] to :logo to accept single file
          service_delivery: {}
        )
      end
    else
      # Fallback for simple updates
      params.permit(
        :name,
        :website,
        :email,
        :cost,
        :min_age,
        :max_age,
        :waitlist,
        :telehealth_services,
        :spanish_speakers,
        :at_home_services,
        :in_clinic_services,
        :status,
        :provider_type,
        :in_home_only,
        :logo,  # Changed from logo: [] to :logo to accept single file
        service_delivery: {}
      )
    end
  end
end