SMTP_SETTINGS = {
  address: Figaro.env.smtp_address,
  authentication: 'login',
  domain: Figaro.env.smtp_domain,
  enable_starttls_auto: true,
  password: Figaro.env.smtp_password,
  port: '587',
  user_name: Figaro.env.smtp_username,
}.freeze

if Figaro.env.email_recipients.present?
  Mail.register_interceptor RecipientInterceptor.new(Figaro.env.email_recipients)
end
