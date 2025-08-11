class Api::V1::PasswordResetsController < ApplicationController
  skip_before_action :authenticate_client, only: [:create, :update, :validate_token]

  def create
    # Use the exact same email verification logic as the AuthenticationController login
    user = User.find_by(email: params[:email])
    
    if user
      # Check if a password reset was recently sent (within last 5 minutes)
      if user.reset_password_sent_at && user.reset_password_sent_at > 5.minutes.ago
        render json: { message: 'Password reset instructions already sent. Please check your email.' }, status: :ok
        return
      end
      
      begin
        user.send_reset_password_instructions
        render json: { message: 'Password reset instructions sent to your email' }, status: :ok
      rescue => e
        Rails.logger.error "Email sending failed: #{e.message}"
        render json: { error: 'Failed to send password reset email. Please try again later.' }, status: :internal_server_error
      end
    else
      # Use the same response logic as login - don't reveal if email exists or not
      render json: { error: 'If the email exists, password reset instructions have been sent' }, status: :ok
    end
  end

  def update
    Rails.logger.info "Password reset params: #{reset_password_params.inspect}"
    
    # Use Devise's proper method to find user by reset token
    user = User.with_reset_password_token(reset_password_params[:reset_password_token])
    
    Rails.logger.info "User found: #{user.inspect}" if user
    
    if user && user.reset_password_period_valid?
      # Use Devise's reset_password method which handles token clearing automatically
      if user.reset_password(reset_password_params[:password], reset_password_params[:password_confirmation])
        render json: { message: 'Password updated successfully' }, status: :ok
      else
        render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: ['Reset password token is invalid or expired'] }, status: :unprocessable_entity
    end
  end

  def validate_token
    # Use Devise's proper method to find user by reset token
    user = User.with_reset_password_token(params[:token])
    
    if user && user.reset_password_period_valid?
      render json: { valid: true, message: 'Token is valid' }, status: :ok
    else
      render json: { valid: false, message: 'Token is invalid or expired' }, status: :unprocessable_entity
    end
  end

  private

  def reset_password_params
    # Handle both flat and nested parameter structures
    if params[:password_reset].present?
      params.require(:password_reset).permit(:reset_password_token, :password, :password_confirmation)
    else
      params.permit(:reset_password_token, :password, :password_confirmation)
    end
  end
end
