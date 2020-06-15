class CleanUsersService
  def self.call
    count = User.where(last_sign_in_at: nil).
            where('created_at < ?', 14.days.ago).
            delete_all

    if count > 0
      accounts = "account".pluralize(count)
      Rails.logger.info("Deleted #{count} unauthenticated #{accounts}")
    end
  end
end
