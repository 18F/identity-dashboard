module UserHelper # :nodoc:
  def deadline(user)
    (user.created_at + 14.days).strftime('%m/%d/%Y')
  end

  def can_delete_unconfirmed_users?(current_user, users)
    current_user.admin? && users.any? { |user| user.unconfirmed? }
  end

  def sign_in_icon(user)
    return 'alerts/success.svg' if user.uuid?
    return 'alerts/error.svg' if user.unconfirmed?

    'alerts/warning.svg'
  end

  def title(user)
    return unless !user.uuid? && user.unconfirmed?

    "Sign-in deadline: #{deadline(user)}"
  end

  def caption(user)
    return 'User has signed in' if user.uuid?
    return 'Unconfirmed user' if user.unconfirmed?

    'User has not yet signed in'
  end

  def alt(user)
    return '' if user.uuid? || !user.unconfirmed?

    "Sign-in deadline: #{deadline(user)}"
  end
end
