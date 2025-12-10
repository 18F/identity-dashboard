require 'rails_helper'

describe UserPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:logingov_readonly) { create(:logingov_readonly) }
  let(:ic_user) { create(:user) }
  let(:restricted_user) { create(:restricted_ic) }
  let(:user_record) { build(:user) }
  let(:partner_admin) { build(:user, :partner_admin) }
  let(:partner_developer) { build(:user, :partner_developer) }
  let(:partner_readonly) { build(:user, :partner_readonly) }

  require 'rails_helper'

  permissions :manage_users? do
    it 'authorizes login.gov admin on for the class' do
      expect(UserPolicy).to permit(logingov_admin, User)
    end

    it 'forbids non-admin for the class' do
      partner_admin = build(:team_membership, :partner_admin).user
      expect(UserPolicy).to_not permit(partner_admin, User)
    end

    it 'forbids partner admin to edit login.gov admin users even if they share a team' do
      partner_admin = create(:team_membership, :partner_admin).user
      logingov_admin.teams << partner_admin.teams.first
      expect(UserPolicy).to_not permit(partner_admin, logingov_admin)
    end
  end

  permissions :index? do
    it 'authorizes a login.gov admin' do
      expect(UserPolicy).to permit(logingov_admin, user_record)
    end

    it 'authorizes login.gov readonly' do
      expect(UserPolicy).to permit(logingov_readonly, user_record)
    end

    it 'does not authorize an allowlisted user' do
      expect(UserPolicy).to_not permit(ic_user, user_record)
    end

    it 'does not authorize other users' do
      expect(UserPolicy).to_not permit(restricted_user, user_record)
    end
  end

  permissions :none? do
    it 'gives access to login.gov admin' do
      expect(UserPolicy).to permit(logingov_admin, user_record)
    end

    it 'gives access to an IC user' do
      expect(UserPolicy).to permit(ic_user, user_record)
    end

    it 'gives access to restricted ICs' do
      expect(UserPolicy).to permit(restricted_user, user_record)
    end
  end

  permissions :above_readonly_role? do
    it 'forbids access to login.gov readonly' do
      expect(UserPolicy).to_not permit(logingov_readonly, user_record)
    end

    it 'forbids access to a partner readonly' do
      expect(UserPolicy).to_not permit(partner_readonly, user_record)
    end

    it 'gives access to login.gov admin' do
      expect(UserPolicy).to permit(logingov_admin, user_record)
    end

    it 'gives access to partner admin' do
      expect(UserPolicy).to permit(partner_admin, user_record)
    end

    it 'gives access to partner developer' do
      expect(UserPolicy).to permit(partner_developer, user_record)
    end
  end
end
