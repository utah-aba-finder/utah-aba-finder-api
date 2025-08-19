class ApplicationMailer < ActionMailer::Base
  default from: "autismserviceslocator24@gmail.com"
  default reply_to: "registration@autismserviceslocator.com"
  layout "mailer"
end
