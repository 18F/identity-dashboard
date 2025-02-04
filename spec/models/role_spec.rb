require 'rails_helper'

RSpec.describe Role do
  it 'knows which roles are legacy admin' do
    expect(Role.site_admin).to be_legacy_admin
    other_roles = Role::ACTIVE_ROLES_NAMES.except(:logingov_admin)
    other_roles.each do |other_role|
      expect(Role.find_by(name: other_role)).not_to be_legacy_admin
    end
  end
end
