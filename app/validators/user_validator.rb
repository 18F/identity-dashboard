class UserValidator < ActiveModel::Validator
  def validate(record)
    if User.find_by_email(record.email)
      record.errors.add(:email, I18n.t('notices.user_already_exists'))
    end
  end
end
