module MailerSpecHelper
  delegate :deliveries, to: :'ActionMailer::Base'
end

RSpec.configure do |config|
  include MailerSpecHelper

  config.before(:each) do
    deliveries.clear
  end
end
