require 'rails_helper'

RSpec.describe Role, type: :model do
  describe '.seed' do
    it 'knows which roles are legacy admin' do
      site_admin = Role.find 'Login.gov Admin'
      expect(site_admin.legacy_admin?).to be_truthy
      other_roles = Role::ALL_ROLES - [site_admin]
      other_roles.each do |other_role|
        expect(other_role.legacy_admin?).to be_falsey
      end
    end
  end
end
