class Api::V1::Admin::ProviderClaimRequestsController < Api::V1::Admin::BaseController
  def index
    begin
      page = params[:page] || 1
      per_page = params[:per_page] || 25
      status_filter = params[:status]
      search = params[:search]
      
      claim_requests = ProviderClaimRequest.includes(:provider, :reviewed_by)
      
      # Log for debugging
      Rails.logger.info "Loading claim requests, total count: #{claim_requests.count}"
      
      # Apply filters
      claim_requests = claim_requests.where(status: status_filter) if status_filter.present?
      if search.present?
        claim_requests = claim_requests.joins(:provider)
                                      .where("LOWER(provider_claim_requests.claimer_email) ILIKE ? OR LOWER(providers.name) ILIKE ? OR LOWER(providers.email) ILIKE ?",
                                             "%#{search}%", "%#{search}%", "%#{search}%")
      end
      
      # Order by most recent first
      claim_requests = claim_requests.order(created_at: :desc)
      
      # Pagination
      total_count = claim_requests.count
      claim_requests = claim_requests.offset((page.to_i - 1) * per_page.to_i).limit(per_page.to_i)
      
      render json: {
        claim_requests: claim_requests.map do |request|
          provider = request.provider
          {
            id: request.id,
            provider: provider ? {
              id: provider.id,
              name: provider.name,
              email: provider.email,
              website: provider.website
            } : {
              id: request.provider_id,
              name: "Provider Not Found (ID: #{request.provider_id})",
              email: nil,
              website: nil
            },
            claimer_email: request.claimer_email,
            status: request.status,
            reviewed_by: request.reviewed_by ? {
              id: request.reviewed_by.id,
              email: request.reviewed_by.email
            } : nil,
            reviewed_at: request.reviewed_at,
            admin_notes: request.admin_notes,
            rejection_reason: request.rejection_reason,
            created_at: request.created_at,
            updated_at: request.updated_at
          }
        end,
        pagination: {
          page: page.to_i,
          per_page: per_page.to_i,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page.to_i).ceil
        },
        filters: {
          status: status_filter,
          search: search
        }
      }, status: :ok
    rescue => e
      Rails.logger.error "Error in admin claim requests index: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
  
  def show
    begin
      claim_request = ProviderClaimRequest.includes(:provider, :reviewed_by).find(params[:id])
      provider = claim_request.provider
      
      render json: {
        claim_request: {
          id: claim_request.id,
          provider: provider ? {
            id: provider.id,
            name: provider.name,
            email: provider.email,
            website: provider.website
          } : {
            id: claim_request.provider_id,
            name: "Provider Not Found (ID: #{claim_request.provider_id})",
            email: nil,
            website: nil
          },
          claimer_email: claim_request.claimer_email,
          status: claim_request.status,
          reviewed_by: claim_request.reviewed_by ? {
            id: claim_request.reviewed_by.id,
            email: claim_request.reviewed_by.email
          } : nil,
          reviewed_at: claim_request.reviewed_at,
          admin_notes: claim_request.admin_notes,
          rejection_reason: claim_request.rejection_reason,
          created_at: claim_request.created_at,
          updated_at: claim_request.updated_at
        }
      }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Claim request not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin claim requests show: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
  
  def approve
    begin
      claim_request = ProviderClaimRequest.find(params[:id])
      admin_notes = params[:admin_notes]
      
      if claim_request.approve!(current_user, admin_notes)
        render json: {
          success: true,
          message: "Claim request approved successfully",
          claim_request: {
            id: claim_request.id,
            status: claim_request.status,
            provider: {
              id: claim_request.provider.id,
              name: claim_request.provider.name
            },
            claimer_email: claim_request.claimer_email
          }
        }, status: :ok
      else
        render json: {
          error: "Failed to approve claim request",
          errors: claim_request.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Claim request not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin claim requests approve: #{e.class.name} - #{e.message}"
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
  
  def reject
    begin
      claim_request = ProviderClaimRequest.find(params[:id])
      rejection_reason = params[:rejection_reason]
      admin_notes = params[:admin_notes]
      
      if claim_request.reject!(current_user, rejection_reason, admin_notes)
        render json: {
          success: true,
          message: "Claim request rejected",
          claim_request: {
            id: claim_request.id,
            status: claim_request.status
          }
        }, status: :ok
      else
        render json: {
          error: "Failed to reject claim request",
          errors: claim_request.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Claim request not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin claim requests reject: #{e.class.name} - #{e.message}"
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
  
  def resend_email
    begin
      claim_request = ProviderClaimRequest.find(params[:id])
      
      case claim_request.status
      when 'approved'
        # Find the user associated with this claim
        user = User.find_by(email: claim_request.claimer_email.downcase)
        
        if user.nil?
          render json: {
            error: "User account not found for this claim request",
            suggestion: "The user account may have been deleted. You may need to approve the claim again."
          }, status: :not_found
          return
        end
        
        # Resend the approval email
        ProviderClaimMailer.claim_approved(claim_request, user).deliver_later
        
        render json: {
          success: true,
          message: "Approval email resent successfully to #{claim_request.claimer_email}",
          claim_request: {
            id: claim_request.id,
            status: claim_request.status,
            claimer_email: claim_request.claimer_email
          }
        }, status: :ok
        
      when 'rejected'
        # Resend the rejection email
        ProviderClaimMailer.claim_rejected(claim_request).deliver_later
        
        render json: {
          success: true,
          message: "Rejection email resent successfully to #{claim_request.claimer_email}",
          claim_request: {
            id: claim_request.id,
            status: claim_request.status,
            claimer_email: claim_request.claimer_email
          }
        }, status: :ok
        
      when 'pending'
        # Resend the submission confirmation email
        ProviderClaimMailer.claim_submitted(claim_request).deliver_later
        
        render json: {
          success: true,
          message: "Confirmation email resent successfully to #{claim_request.claimer_email}",
          claim_request: {
            id: claim_request.id,
            status: claim_request.status,
            claimer_email: claim_request.claimer_email
          }
        }, status: :ok
        
      else
        render json: {
          error: "Unknown claim request status: #{claim_request.status}"
        }, status: :unprocessable_entity
      end
      
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Claim request not found" }, status: :not_found
    rescue => e
      Rails.logger.error "Error in admin claim requests resend_email: #{e.class.name} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
    end
  end
end
