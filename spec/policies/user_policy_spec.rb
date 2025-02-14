require 'rails_helper'

describe UserPolicy do
  let(:admin) { create(:admin) }
  let(:ic_user) { create(:user) }
  let(:restricted_user) { create(:restricted_ic) }
  let(:user_record) { build(:user) }

  require 'rails_helper'

  permissions :manage_users? do
    it 'authorizes an admin' do
      expect(UserPolicy).to permit(admin, user_record)
    end

    it 'does not authorize an allowlisted user' do
      expect(UserPolicy).to_not permit(ic_user, user_record)
    end

    it 'does not authorize other users' do
      expect(UserPolicy).to_not permit(restricted_user, user_record)
    end

    it 'authorizes admin on for the class' do
      expect(UserPolicy).to permit(admin, User)
    end

    it 'forbids non-admin for the class' do
      partner_admin = build(:user_team, :partner_admin).user
      expect(UserPolicy).to_not permit(partner_admin, User)
    end

    it 'forbids partner admin to edit site admin users even if they share a team' do
      partner_admin = create(:user_team, :partner_admin).user
      admin.teams << partner_admin.teams.first
      expect(UserPolicy).to_not permit(partner_admin, admin)
    end
  end

  permissions :none? do
    it 'gives access to admin' do
      expect(UserPolicy).to permit(admin, user_record)
    end

    it 'gives access to an IC user' do
      expect(UserPolicy).to permit(ic_user, user_record)
    end

    it 'gives access to restricted ICs' do
      expect(UserPolicy).to permit(restricted_user, user_record)
    end
  end
end
