module MailerSpecHelper
  def deliveries
    ActionMailer::Base.deliveries
  end
end

RSpec.configure do |config|
  include MailerSpecHelper

  config.before do
    deliveries.clear
  end
end
