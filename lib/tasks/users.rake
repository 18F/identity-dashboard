namespace :users do
  USAGE_WARNING = <<~WARN.freeze
    WARNING: Running this task without USER argument is a noop
    Usage: rake users:make_admin USER=first.last@email.com,First,Last
  WARN

  desc 'Promote a user in the dashboard to admin'
  task make_admin: :environment do
    user_info = ENV['USER']
    if user_info.blank? || user_info.split(',').count < 3
      warn(USAGE_WARNING)
    else
      new_admin = User.new
      new_admin.email      = user_info.split(',')[0]
      new_admin.first_name = user_info.split(',')[1]
      new_admin.last_name  = user_info.split(',')[2]
      new_admin.admin      = true
      new_admin.save
    end
  end
end
