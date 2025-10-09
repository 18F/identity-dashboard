# Helper for Team view
module TeamHelper
  ALLOWLISTED_DOMAINS = %w[.mil .gov .fed.us].freeze

  def can_edit_teams?(user)
    !user.teams.empty? || user.admin?
  end

  def can_create_teams?(user)
    allowlisted_user?(user) || user.admin?
  end

  def can_delete_team?(user)
    user.admin?
  end

  def allowlisted_user?(user)
    ALLOWLISTED_DOMAINS.any? { |domain| user.email.end_with? domain }
  end
end
