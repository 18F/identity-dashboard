SMTP_SETTINGS = {
  address: Figaro.env.SMTP_ADDRESS,
  authentication: 'login',
  domain: Figaro.env.SMTP_DOMAIN,
  enable_starttls_auto: true,
  password: Figaro.env.SMTP_PASSWORD,
  port: '587',
  user_name: Figaro.env.SMTP_USERNAME
}.freeze

if Figaro.env.EMAIL_RECIPIENTS.present?
  Mail.register_interceptor RecipientInterceptor.new(Figaro.env.email_recipients)
end
