class UserMailer < ApplicationMailer

  def admin_email_address
    ENV['ADMIN_EMAIL'] || 'identity-dashboard-admin@18f.gov'
  end

  def admin_new_application(app)
    @application = app
    mail(
      to: admin_email_address,
      subject: "New Identity application #{app.issuer}"
    )
  end

  def user_new_application(app)
    @application = app
    mail(
      to: app.user.email,
      subject: "New Identity application #{app.issuer}"
    )
  end

  def admin_approved_application(app)
    @application = app
    mail(
      to: admin_email_address,
      subject: "Identity application approved #{app.issuer}"
    )
  end

  def user_approved_application(app)
    @application = app
    mail(
      to: app.user.email,
      subject: "Identity application approved #{app.issuer}"
    )
  end
end
