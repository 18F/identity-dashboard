require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which role is the site admin role' do
    active_roles = Role::ACTIVE_ROLES_NAMES.keys.map { |name| Role.find_by(name:) }
    expect(active_roles[0]).to eq(Role::LOGINGOV_ADMIN)
  end

  it 'has no duplicate active roles' do
    active_roles = Role::ACTIVE_ROLES_NAMES.keys.map { |name| Role.find_by(name:) }
    expect(active_roles.uniq.map(&:friendly_name)).to eq(Role::ACTIVE_ROLES_NAMES.values)
  end
end
