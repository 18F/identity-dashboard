# A Role describes a user's role on teams.
# A role has a `name`, which is our internal name that will be consistent between environments
# and a `friendly_name` which can be easily edited without modifying the internal name.
#
# Things this class does not do:
#
# The assignment of which user has which role currently exists in the UserTeams table.
#
# The enforcement of permissions should occur through the relevant Pundit policy class for
# the object the user is accessing.
#
class Role < ApplicationRecord
  attr_reader :name, :friendly_name

  ROLES = {
    :logingov_admin => 'Login.gov Admin',
    :partner_admin => 'Partner Admin',
    :partner_dev => 'Partner Developer',
    :partner_readonly => 'Partner Readonly',
  }.freeze
  SITE_ADMIN = ROLES[:logingov_admin].freeze

  # Don't use `Role.new` from outside the class itself.
  # Generally, you'll want to use `Role.find_by` instead
  # def initialize(name:, friendly_name: nil)
  #   @name = name
  #   @friendly_name = friendly_name || name
  # end

  # ACTIVE_ROLES = ROLES.each do |r, f|
  #   new(name: r, friendly_name: f)
  # end

  # def self.find_by(name:)
  #   ACTIVE_ROLES.find { |r| r.name == name }
  # end

  def legacy_admin?
    name == 'logingov_admin'
  end
end
