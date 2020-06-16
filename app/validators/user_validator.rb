class UserValidator < ActiveModel::Validator
  def validate(record)
    return unless User.where(email: record.email).exists?
    record.errors.add(:email, I18n.t('notices.user_already_exists'))
  end
end
