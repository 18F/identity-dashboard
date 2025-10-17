# Creates and renders a CSV of per-issuer TeamMembership data
#
# This mimics the format in the [Partnerships CRM Airtable](
# https://airtable.com/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk/viw4RRFq5OHG9PALS?blocks=bipdcitNNhTQelnMu
# ) (Partner Portal Admins Confirmed tab) and  is a security requirement, for auditability.
class UserPermissionsCsv
  HEADER_ROW = ['Issuer', 'Team', 'Team UUID', 'User email', 'Role']
  attr_reader :user_permissions

  def initialize(user_permissions)
    @user_permissions = user_permissions
  end

  def render_in(view_context)
    view_context.render body: user_permissions_csv
  end

  def format
    :csv
  end

  private

  def user_permissions_csv
    CSV.generate do |csv|
      csv << HEADER_ROW
      user_permissions.each do |membership|
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
