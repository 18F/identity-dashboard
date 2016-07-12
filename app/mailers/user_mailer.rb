class UserMailer < ApplicationMailer
  def admin_email_address
    ENV['ADMIN_EMAIL'] || 'identity-dashboard-admin@18f.gov'
  end

  def welcome_new_user(user)
    mail(
      to: user.email,
      subject: I18n.t('mailer.welcome.subject')
    )
  end

  def admin_new_service_provider(app)
    @service_provider = app
    mail(
      to: admin_email_address,
      subject: I18n.t('mailer.new_service_provider.subject', id: app.issuer)
    )
  end

  def user_new_service_provider(app)
    @service_provider = app
    mail(
      to: app.user.email,
      subject: I18n.t('mailer.new_service_provider.subject', id: app.issuer)
    )
  end

  def admin_approved_service_provider(app)
    @service_provider = app
    mail(
      to: admin_email_address,
      subject: I18n.t('mailer.approved_service_provider.subject', id: app.issuer)
    )
  end

  def user_approved_service_provider(app)
    @service_provider = app
    mail(
      to: app.user.email,
      subject: I18n.t('mailer.approved_service_provider.subject', id: app.issuer)
    )
  end
end
