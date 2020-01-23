module TeamHelper
  def can_edit_teams?(user)
    !user.teams.empty? || user.admin?
  end
end
