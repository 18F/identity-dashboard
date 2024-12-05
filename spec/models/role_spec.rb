require 'rails_helper'

RSpec.describe Role, type: :model do
  describe '.seed' do
    it 'knows which roles are legacy admin' do
      expect(Role::SITE_ADMIN.legacy_admin?).to be_truthy
      other_roles = Role::ACTIVE_ROLES - [Role::SITE_ADMIN]
      other_roles.each do |other_role|
        expect(other_role.legacy_admin?).to be_falsey
      end
    end
  end
end
