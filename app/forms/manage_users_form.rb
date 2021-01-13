class ManageUsersForm
  include ActiveModel::Model

  attr_reader :team, :user_emails

  validate :user_emails_is_not_empty
  validate :user_emails_are_valid_email_addresses

  def initialize(team)
    @team = team
    @user_emails = team.users.map(&:email)
  end

  def submit(user_emails:)
    # Devise makes emails case insensitive by downcasing prior to saving
    @user_emails = user_emails.map(&:downcase)

    return false unless valid?

    result = team.update(users: users_from_user_emails)
    errors.merge!(team.errors)
    result
  end

  private

  def users_from_user_emails
    missing_users = missing_emails.map { |e| User.new(email: e) }
    (existing_users + missing_users).sort_by(&:email)
  end

  def missing_emails
    existing_emails = existing_users.map(&:email)
    user_emails.filter { |email| !existing_emails.include? email }
  end

  def existing_users
    User.where(email: user_emails).to_a
  end

  def user_emails_is_not_empty
    return unless user_emails.empty?

    errors.add(:base, 'You must submit at least one email address')
  end

  def user_emails_are_valid_email_addresses
    user_emails.each do |email|
      next if email.match(Devise.email_regexp)
      errors.add(:base, "#{email} is not a valid email address")
    end
  end
end
