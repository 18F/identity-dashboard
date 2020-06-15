class CleanUsersService
  def self.call
    count = User.where(last_sign_in_at: nil).
            where('created_at < ?', 14.days.ago).
            delete_all

    return unless count.positive?

    accounts = 'account'.pluralize(count)
    Rails.logger.info("Deleted #{count} unauthenticated #{accounts}")
  rescue ActiveRecord::NoDatabaseError
    Rails.logger.info('Database not yet available')
  end
end
