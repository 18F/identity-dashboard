require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which role is the site admin role' do
    active_roles = Role::ROLES_NAMES.map { |name| Role.find_by(name:) }
    expect(active_roles[0]).to eq(Role::LOGINGOV_ADMIN)
  end

  it 'has no duplicate active roles' do
    active_roles = Role::ROLES_NAMES.map { |name| Role.find_by(name:) }
    expect(active_roles.map(&:name)).to eq(Role::ROLES_NAMES)
  end
end
