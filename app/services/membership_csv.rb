class MembershipCsv
  MEMBERSHIPS_HEADER_ROW = ['User email', 'Role', 'Team']
  attr_reader :memberships

  def initialize(memberships)
    @memberships = memberships
  end

  def render_in(view_context)
    view_context.render body: membership_csv
  end

  def format
    :csv
  end

  private

  def membership_csv
    CSV.generate do |csv|
      csv << MEMBERSHIPS_HEADER_ROW
      memberships.each do |membership|
        csv << [membership.user.email, membership.role&.friendly_name, membership.team]
      end
    end
  end
end
