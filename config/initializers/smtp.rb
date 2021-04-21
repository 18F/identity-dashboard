SMTP_SETTINGS = {
  address: IdentityConfig.store.smtp_address,
  authentication: 'login',
  domain: IdentityConfig.store.smtp_domain,
  enable_starttls_auto: true,
  password: IdentityConfig.store.smtp_password,
  port: '587',
  user_name: IdentityConfig.store.smtp_username,
}.freeze

if IdentityConfig.store.email_recipients.present?
  Mail.register_interceptor RecipientInterceptor.new(IdentityConfig.store.email_recipients)
end
