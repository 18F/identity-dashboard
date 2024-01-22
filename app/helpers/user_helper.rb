module UserHelper
  def deadline(user)
    (user.created_at + 14.days).strftime('%m/%d/%Y')
  end

  def can_delete_unconfirmed_users?(current_user, users)
    current_user.admin? && users.any? { |user| user.unconfirmed? }
  end

  def sign_in_icon(user)
    return 'img/alerts/success.svg' if user.uuid?
    return 'img/alerts/warning.svg' if user.unconfirmed?
    'img/alerts/error.svg'
  end

  def title(user)
    return 'User has signed in' if user.uuid?
    return "Unconfirmed user (sign-in deadline: #{deadline(user)})" if user.unconfirmed?
    'User has not yet signed in'
  end

  def alt(user)
    "Icon indicating #{title(user)}".capitalize
  end
end
