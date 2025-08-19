class ApplicationMailer < ActionMailer::Base
  default from: "noreply@autismserviceslocator.com"
  default reply_to: "registration@autismserviceslocator.com"
  layout "mailer"
end
