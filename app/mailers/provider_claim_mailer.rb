class ProviderClaimMailer < ApplicationMailer
  def claim_submitted(claim_request)
    @claim_request = claim_request
    @provider = claim_request.provider
    
    mail(
      to: @claim_request.claimer_email,
      subject: "Account Claim Request Received - #{@provider&.name || 'Provider Account'}"
    )
  end
  
  def claim_approved(claim_request, user)
    @claim_request = claim_request
    @provider = claim_request.provider
    @user = user
    @password = user.instance_variable_get(:@plain_password)
    
    mail(
      to: @claim_request.claimer_email,
      subject: "Account Claim Approved - #{@provider.name}"
    )
  end
  
  def claim_rejected(claim_request)
    @claim_request = claim_request
    @provider = claim_request.provider
    
    mail(
      to: @claim_request.claimer_email,
      subject: "Account Claim Request Update - #{@provider.name}"
    )
  end
end

