require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which roles are legacy admin' do
    expect(Role::LOGINGOV_ADMIN).to be_legacy_admin
    other_roles = Role::ACTIVE_ROLES_NAMES.except(:logingov_admin)
    other_roles.each do |other_role|
      expect(Role.find_by(name: other_role)).to_not be_legacy_admin
    end
  end
end
