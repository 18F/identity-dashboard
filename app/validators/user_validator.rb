# Validates the existence of a given user email address
class UserValidator < ActiveModel::Validator
  def validate(record)
    return unless User.exists?(email: record.email)

    record.errors.add(:email, I18n.t('notices.user_already_exists'))
  end
end
