# The Internal Team is used to define who can be a `logingov_admin`.
class Seeders::Teams < Seeders::BaseSeeder
  def seed
    return if Team.internal_team

    team = Team.create!(attributes)
    logger.info "Created internal team ID '#{team.id}' with attributes '#{attributes}'"
  end

  private

  def attributes
    {
      name: Team::INTERNAL_TEAM_NAME,
      description: Team::INTERNAL_TEAM_DESCRIPTION,
      agency_id: Seeders::AgencySeeder.internal_agency_data[:id],
      # Version character set to 8 to indicate this was not generated on the fly
      # Acceptable as per rfc9562. Without this, tests may fail.
      uuid: 'e5b7ca57-aabd-857f-9d9a-a59a46116e93',
    }
  end
end
