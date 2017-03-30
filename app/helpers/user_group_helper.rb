module UserGroupHelper
  def can_edit_user_groups?(user)
    user.user_group_id? || user.admin?
  end
end
