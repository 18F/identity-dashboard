module TeamHelper
  ALLOWED_DOMAINS = /@.+\.(mil|gov|fed\.us|state\..+\.us)$/

  def can_edit_teams?(user)
    !user.teams.empty? || user.admin?
  end

  def can_create_teams?(user)
    allowed_email? || user.admin?
  end

  def can_delete_team?(user)
    user.admin?
  end

  def allowed_email?
    ALLOWED_DOMAINS.match?(current_user.email)
  end
end
