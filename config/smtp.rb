SMTP_SETTINGS = {
  address: ENV.fetch('SMTP_ADDRESS'), # example: "smtp.mandrillapp.com"
  authentication: 'login',
  domain: ENV.fetch('SMTP_DOMAIN'), # example: "18f.gsa.gov"
  enable_starttls_auto: true,
  password: ENV.fetch('SMTP_PASSWORD'),
  port: '587',
  user_name: ENV.fetch('SMTP_USERNAME')
}.freeze

if ENV['EMAIL_RECIPIENTS'].present?
  Mail.register_interceptor RecipientInterceptor.new(ENV['EMAIL_RECIPIENTS'])
end
