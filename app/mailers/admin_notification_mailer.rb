class AdminNotificationMailer < ApplicationMailer
  DEFAULT_ADMIN_EMAIL = "jordanwilliamson@autismserviceslocator.com".freeze

  # One or more addresses from ADMIN_NOTIFICATION_EMAIL (comma-separated).
  # Blank / whitespace-only ENV falls through to DEFAULT (Ruby treats "" as truthy with `||`).
  def self.admin_notification_recipients
    raw = ENV["ADMIN_NOTIFICATION_EMAIL"].presence
    return [DEFAULT_ADMIN_EMAIL] if raw.blank?

    list = raw.split(",").map(&:strip).reject(&:blank?)
    list.presence || [DEFAULT_ADMIN_EMAIL]
  end

  def new_provider_registration(registration)
    @registration = registration.reload
    @registration_review_url = registration_admin_review_url(@registration)
    @separate_applicant_inbox = @registration.separate_applicant_inbox?
    @applicant_inbox_email = @registration.correspondence_email if @separate_applicant_inbox
    to_list = self.class.admin_notification_recipients
    @admin_email = to_list.join(", ")

    cc_emails = admin_notification_cc_list

    mail(
      to: to_list,
      cc: cc_emails.presence,
      subject: "New Provider Registration: #{registration.provider_name}"
    )
  end

  def new_provider_claim_request(claim_request)
    @claim_request = claim_request
    @provider = claim_request.provider
    to_list = self.class.admin_notification_recipients
    @admin_email = to_list.join(", ")

    cc_emails = admin_notification_cc_list
    provider_name = @provider&.name || "Unknown Provider"

    mail(
      to: to_list,
      cc: cc_emails.presence,
      subject: "New Provider Account Claim Request: #{provider_name}"
    )
  end

  def password_changed(user)
    @user = user
    @provider = user.provider
    to_list = self.class.admin_notification_recipients
    @admin_email = to_list.join(", ")

    cc_emails = admin_notification_cc_list
    provider_name = @provider&.name || "No Provider Linked"

    mail(
      to: to_list,
      cc: cc_emails.presence,
      subject: "Password Changed: #{user.email} (#{provider_name})"
    )
  end

  private

  def admin_notification_cc_list
    ENV["ADMIN_NOTIFICATION_CC"].presence&.split(",")&.map(&:strip)&.reject(&:blank?) || []
  end

  # Mailer views have no HTTP request; never use request.base_url there.
  # Optional: ADMIN_APP_BASE_URL=https://www.autismserviceslocator.com (no trailing slash)
  def registration_admin_review_url(registration)
    base = ENV["ADMIN_APP_BASE_URL"].presence&.chomp("/")
    if base.blank?
      host = Rails.application.config.action_mailer.default_url_options&.dig(:host)
      host = ENV["HOST"].to_s.sub(%r{\Ahttps?://}, "").presence if host.blank?
      host ||= "www.autismserviceslocator.com"
      base = "https://#{host}"
    end
    "#{base}/admin/provider_registrations/#{registration.id}"
  end
end
