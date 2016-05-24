class ApplicationMailer < ActionMailer::Base
  include ActionMailer::Text

  default from: 'identity-dashboard@18f.gov'
end
