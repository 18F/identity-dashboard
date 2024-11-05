require 'rails_helper'

RSpec.describe Role, type: :model do
  describe '.seed' do
    it 'creates a missing role' do
      expect do
        Role.seed
      end.to(change {Role.count}.by(4))
      admin_roles = Role.where(name: 'Login Admin')
      expect(admin_roles.count).to be(1)
    end

    it 'does not create a role that already exists' do
      existing_role = create(:role, name: 'Login.gov Admin')
      existing_attributes = existing_role.attributes
      Role.seed
      admin_roles = Role.where(name: 'Login Admin')
      expect(admin_roles.count).to be(1)
      expect(admin_roles.first.attributes).to eq(existing_attributes)
    end
  end
end
