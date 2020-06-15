lambda do
  config = Rails.application.config
  config.after_initialize do
    interval = Figaro.env.clean_users_job_frequency_seconds || 30.days
    CleanUsersJob.new.perform(interval.to_i)
  end
end.call
