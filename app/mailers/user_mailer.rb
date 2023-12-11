class UserMailer < ApplicationMailer
  def welcome_new_user(user)
    mail(
      to: user.email,
      subject: I18n.t('mailer.welcome.subject'),
    )
  end
end
