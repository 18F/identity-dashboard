class UserMailer < ApplicationMailer
  def admin_email_address
    ENV['ADMIN_EMAIL'] || 'identity-dashboard-admin@18f.gov'
  end

  def welcome_new_user(user)
    mail(
      to: user.email,
      subject: I18n.t('dashboard.mailer.welcome.subject')
    )
  end

  def admin_new_application(app)
    @application = app
    mail(
      to: admin_email_address,
      subject: I18n.t('dashboard.mailer.new_application.subject', id: app.issuer)
    )
  end

  def user_new_application(app)
    @application = app
    mail(
      to: app.user.email,
      subject: I18n.t('dashboard.mailer.new_application.subject', id: app.issuer)
    )
  end

  def admin_approved_application(app)
    @application = app
    mail(
      to: admin_email_address,
      subject: I18n.t('dashboard.mailer.approved_application.subject', id: app.issuer)
    )
  end

  def user_approved_application(app)
    @application = app
    mail(
      to: app.user.email,
      subject: I18n.t('dashboard.mailer.approved_application.subject', id: app.issuer)
    )
  end
end
