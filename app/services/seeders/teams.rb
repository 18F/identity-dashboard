class Seeders::Teams < Seeders::AbstractSeeder
  INTERNAL_TEAM_NAME = 'Login.gov Internal Team'.freeze
  DESCRIPTION = 'This team is for Login.gov teammembers. ' \
    'Do not add people who are not working on Login.gov to this team.'.freeze
  AGENCY_ID = 9 # This is defined as GSA in `config/agencies.yaml`

  def seed
    return if Team.internal_team

    Agency.find_or_create_by(
      id: attributes[:agency_id],
      name: 'General Services Administration',
    )
    team = Team.create(attributes)
    logger.info "Created internal team ID '#{team.id}' with attributes '#{attributes}'"
  end

  private

  def attributes
    {
      name: INTERNAL_TEAM_NAME,
      description: DESCRIPTION,
      agency_id: AGENCY_ID,
    }
  end
end