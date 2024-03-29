module TeamHelper
  WHITELISTED_DOMAINS = %w[.mil .gov .fed.us].freeze

  def can_edit_teams?(user)
    !user.teams.empty? || user.admin?
  end

  def can_create_teams?(user)
    whitelisted_user?(user) || user.admin?
  end

  def can_delete_team?(user)
    user.admin?
  end

  def whitelisted_user?(user)
    WHITELISTED_DOMAINS.any? { |domain| user.email.end_with? domain }
  end
end
