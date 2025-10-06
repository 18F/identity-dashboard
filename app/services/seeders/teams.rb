class Seeders::Teams < Seeders::BaseSeeder # :nodoc:
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
    }
  end
end
