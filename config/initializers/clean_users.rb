lambda do
  config = Rails.application.config
  config.after_initialize do
    CleanUsersJob.new.perform(Figaro.env.clean_users_job_frequency_seconds.to_i)
  end
end.call
