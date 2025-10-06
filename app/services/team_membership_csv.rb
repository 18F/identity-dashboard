# Service for creating and rendering TeamMembership CSVs
class TeamMembershipCsv
  HEADER_ROW = ['User email', 'Role', 'Team']
  attr_reader :team_memberships

  def initialize(team_memberships)
    @team_memberships = team_memberships
  end

  def render_in(view_context)
    view_context.render body: team_membership_csv
  end

  def format
    :csv
  end

  private

  def team_membership_csv
    CSV.generate do |csv|
      csv << HEADER_ROW
      team_memberships.each do |membership|
        csv << [membership.user.email, membership.role&.friendly_name, membership.team]
      end
    end
  end
end
