require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which roles are legacy admin' do
    expect(Role::SITE_ADMIN.legacy_admin?).to be_truthy
    other_roles = Role::ACTIVE_ROLES - [Role::SITE_ADMIN]
    other_roles.each do |other_role|
      expect(other_role.legacy_admin?).to be_falsey
    end
  end

  describe '#to_s' do
    it 'uses the name' do
      expect("#{Role::SITE_ADMIN}").to eq('Login.gov Admin')
      readonly_role = Role.find_by('Partner Readonly')
      expect("#{readonly_role}").to eq('Partner Readonly')
    end
  end
end
