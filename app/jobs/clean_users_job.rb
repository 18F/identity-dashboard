class CleanUsersJob
  include SuckerPunch::Job

  def perform(interval)
    CleanUsersService.call

    CleanUsersJob.perform_in(interval, interval)
  end
end
