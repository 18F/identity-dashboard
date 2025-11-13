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

  context 'on sandbox' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(false)
    end

    describe '#active_roles_names' do
      it 'includes appropriate friendly names' do
        roles_hash = {
          'logingov_admin' => 'Login.gov Admin',
          'partner_admin' => 'Sandbox Partner Admin',
          'partner_developer' => 'Sandbox Team Dev',
          'partner_readonly' => 'Team Readonly',
        }
        expect(Role.new.active_roles_names).to eq(roles_hash)
      end
    end
  end

  context 'on production' do
    before do
      allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
    end

    describe '#active_roles_names' do
      it 'includes appropriate friendly names' do
        roles_hash = {
          'logingov_admin' => 'Login.gov Admin',
          'partner_admin' => 'Production Team Admin',
          'partner_developer' => 'Production Team Dev',
          'partner_readonly' => 'Team Readonly',
        }
        expect(Role.new.active_roles_names).to eq(roles_hash)
      end
    end
  end
end
