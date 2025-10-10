# Service for deleting all unconfirmed Users
#
# This is done via a button on /users
class DeleteUnconfirmedUsers
  def self.call
    count = User.where(last_sign_in_at: nil).
      where('created_at < ?', 14.days.ago).
      delete_all

    Rails.logger.info("Deleted unconfirmed users count=#{count}") if count.positive?
    count
  end
end
