# MakeAdmin designed to be invoked from a rake task
# as such, uses puts() instead of logger
# rubocop:disable Rails/Output
class MakeAdmin
  USAGE_WARNING = <<-WARN.strip.freeze
    WARNING: Running this task without USER argument is a noop
    Usage: rake users:make_admin USER=first.last@email.com,First,Last
  WARN

  attr_reader :email, :first_name, :last_name

  def initialize(user_info)
    @email, @first_name, @last_name = user_info&.split(',') || []
  end

  def call
    raise(USAGE_WARNING) if user_info_invalid?
    if admin.logingov_admin?
      return puts("INFO: User \"#{email}\" already has Login.gov admin privileges.")
    end

    make_admin
    puts "SUCCESS: Promoted \"#{email}\" to Login.gov admin."
  end

  private

  def user_info_invalid?
    [
      email,
      first_name,
      last_name,
    ].map(&:blank?).include?(true)
  end

  def admin
    @admin ||= begin
      new_user_warning = "INFO: User \"#{email}\" not found; creating a new User."
      schrodingers_admin = User.find_or_initialize_by(email:)
      puts new_user_warning unless schrodingers_admin.persisted?
      schrodingers_admin
    end
  end

  def make_admin
    admin.first_name = first_name
    admin.last_name  = last_name
    admin.admin      = true
    admin.save!
  end
end
# rubocop:enable Rails/Output
