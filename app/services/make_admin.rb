# MakeAdmin designed to be invoked from a rake task
# as such, uses puts() instead of logger
# rubocop:disable Rails/Output
class MakeAdmin
  USAGE_WARNING = <<-WARN.strip.freeze
    WARNING: Running this task without USER argument is a noop
    Usage: rake users:make_admin USER=first.last@email.com,First,Last
  WARN

  attr_reader :user_info

  def initialize(user_info)
    @user_info = user_info
  end

  def call
    # binding.pry
    raise(USAGE_WARNING) if user_info_invalid?
    return puts("INFO: User \"#{user_info}\" already has admin privileges.") if admin.admin?
    make_admin
    puts "SUCCESS: Promoted \"#{user_info}\" to admin."
  end

  private

  def user_info_invalid?
    user_info.blank? || user_info.split(',').count < 3
  end

  def admin
    @admin ||= begin
      new_user_warning = "INFO: User \"#{user_info}\" not found; creating a new User."
      schrodingers_admin = User.find_or_initialize_by(email: user_info.split(',')[0])
      puts new_user_warning unless schrodingers_admin.persisted?
      schrodingers_admin
    end
  end

  def make_admin
    admin.first_name = user_info.split(',')[1]
    admin.last_name  = user_info.split(',')[2]
    admin.admin      = true
    admin.save!
  end
end
# rubocop:enable Rails/Output
