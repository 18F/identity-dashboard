# Creates and renders a CSV of per-issuer TeamMembership data
#
# This is a security requirement, for auditability.
class IssuerMembershipCsv
  HEADER_ROW = ['Issuer', 'Team', 'Team UUID', 'User email', 'Role']
  attr_reader :issuer_memberships

  def initialize(issuer_memberships)
    @issuer_memberships = issuer_memberships
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
      issuer_memberships.each do |membership|
        csv << [
          membership[:issuer],
          membership[:team_name],
          membership[:team_uuid],
          membership[:user_email],
          membership[:role],
        ]
      end
    end
  end
end
