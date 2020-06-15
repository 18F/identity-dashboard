class CleanUsersService
  def self.call
    return unless User

    count = User.where(last_sign_in_at: nil).
            where('created_at < ?', 14.days.ago).
            delete_all

    return unless count.positive?

    accounts = 'account'.pluralize(count)
    Rails.logger.info("Deleted #{count} unauthenticated #{accounts}")
  end
end
