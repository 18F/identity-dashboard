class ManageUsersForm
  include ActiveModel::Model

  attr_reader :team, :user_emails

  validate :user_emails_are_valid_email_addresses

  def initialize(team)
    @team = team
    @user_emails = team.users.map(&:email)
  end

  def submit(user_emails:)
    @user_emails = user_emails

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

  def user_emails_are_valid_email_addresses
    user_emails.each do |email|
      next if email.match(Devise.email_regexp)
      errors.add(:base, "#{email} is not a valid email address")
    end
  end

  def existing_users
    User.where('lower(email) IN (?)', user_emails.map(&:downcase)).to_a
  end

  def missing_emails
    existing_emails = existing_users.map { |user| user.email.downcase }
    user_emails.filter { |email| !existing_emails.include? email.downcase }
  end
end