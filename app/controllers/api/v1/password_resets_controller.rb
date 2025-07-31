class Api::V1::PasswordResetsController < ApplicationController
  skip_before_action :authenticate_client, only: [:create, :update, :validate_token]

  # POST /api/v1/password_resets
  # Request password reset
  def create
    client = Client.find_by(email: params[:email])
    
    if client
      begin
        client.send_reset_password_instructions
        render json: { message: 'Password reset instructions sent to your email' }, status: :ok
      rescue => e
        Rails.logger.error "Email sending failed: #{e.message}"
        render json: { error: 'Failed to send password reset email. Please try again later.' }, status: :internal_server_error
      end
    else
      render json: { error: 'Email not found' }, status: :not_found
    end
  end

  # PUT /api/v1/password_resets
  # Reset password with token
  def update
    begin
      client = Client.reset_password_by_token(
        reset_password_token: params[:reset_password_token],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )

      if client.errors.empty?
        render json: { message: 'Password successfully reset' }, status: :ok
      else
        render json: { errors: client.errors.full_messages }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Password reset failed: #{e.message}"
      render json: { error: 'Failed to reset password. Please try again.' }, status: :internal_server_error
    end
  end

  # GET /api/v1/password_resets/validate_token
  # Validate reset token
  def validate_token
    begin
      client = Client.find_by(reset_password_token: params[:reset_password_token])
      
      if client && client.reset_password_period_valid?
        render json: { valid: true }, status: :ok
      else
        render json: { valid: false, error: 'Invalid or expired token' }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Token validation failed: #{e.message}"
      render json: { valid: false, error: 'Failed to validate token' }, status: :internal_server_error
    end
  end
end
