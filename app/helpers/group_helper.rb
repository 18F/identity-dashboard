module GroupHelper
  def can_edit_groups?(user)
    !user.groups.empty? || user.admin?
  end
end
