#:reek:UtilityFunction
module TeamHelper
  WHITELISTED_DOMAINS = %w[.mil .gov .fed.us].freeze

  def can_edit_teams?(user)
    !user.teams.empty? || user.admin?
  end

  def can_create_teams?(user)
    whitelisted_user? || user.admin?
  end

  def can_delete_team?(user, team)
    team.users.include?(user) || user.admin?
  end

  def whitelisted_user?
    WHITELISTED_DOMAINS.any? { |domain| current_user.email.end_with? domain }
  end
end
