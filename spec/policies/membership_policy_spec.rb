require 'rails_helper'

describe MembershipPolicy do
  let(:team) { create(:team) }
  let(:partner_admin_membership) { create(:membership, :partner_admin, team:) }
  let(:partner_developer_membership) { create(:membership, :partner_developer, team:) }
  let(:partner_readonly_membership) { create(:membership, :partner_readonly, team:) }
  let(:partner_admin) { partner_admin_membership.user }
  let(:partner_developer) { partner_developer_membership.user }
  let(:partner_readonly) { partner_readonly_membership.user }
  let(:logingov_admin) { build(:logingov_admin) }
  let(:other_user) { build(:restricted_ic) }
  let(:without_role_membership) { create(:membership) }

  permissions :manage_team_users? do
    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).at_most(1).and_return(false)
    end

    it 'allows team member to manage team users' do
      expect(described_class).to permit(without_role_membership.user, without_role_membership)
    end

    it 'allows login.gov admin to manage team users' do
      expect(described_class).to permit(logingov_admin, without_role_membership)
    end

    it 'does not allow a random user to manage team users' do
      expect(described_class).to_not permit(other_user, without_role_membership)
    end
  end

  permissions :index? do
    it 'allows Partner Admins' do
      expect(described_class).to permit(partner_admin, partner_admin_membership)
    end

    it 'allows Partner Developers' do
      expect(described_class).to permit(partner_developer, partner_developer_membership)
    end

    it 'forbids Partner Readonly' do
      expect(described_class).to_not permit(partner_readonly, partner_readonly_membership)
    end
  end

  permissions :create? do
    it 'allows Partner Admins' do
      new_membership = partner_admin_membership.team.memberships.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Developers' do
      new_membership = partner_developer_membership.team.memberships.build
      expect(described_class).to_not permit(partner_developer, new_membership)
    end

    it 'forbids Partner Readonly' do
      new_membership = partner_readonly_membership.team.memberships.build
      expect(described_class).to_not permit(partner_readonly, new_membership)
    end
  end

  permissions :edit? do
    it 'allows Login Admins' do
      expect(described_class).to permit(logingov_admin, partner_admin_membership)
    end

    it 'allows Partner Admins' do
      new_membership = team.memberships.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Admins for own memberships' do
      expect(described_class).to_not permit(partner_admin, partner_admin_membership)
    end

    context 'with anyone else' do
      %i[partner_readonly partner_developer other_user].each do |role_name|
        it "forbids #{role_name}" do
          new_membership = team.memberships.build
          expect(described_class).to_not permit(send(role_name), new_membership)
        end
      end
    end
  end

  permissions :update? do
    it 'allows Login Admins' do
      expect(described_class).to permit(logingov_admin, partner_admin_membership)
    end

    it 'allows Partner Admins with some role names' do
      new_membership = team.memberships.build(role_name: ['partner_readonly',
                                                         'partner_developer'].sample)
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Admins for own memberships' do
      expect(described_class).to_not permit(partner_admin, partner_admin_membership)
    end

    it 'forbids Partner Admins from picking inappropriate roles' do
      elevated_membership = team.memberships.build(role_name: ['partner_admin',
                                                              'logingov_admin'].sample)
      expect(described_class).to_not permit(partner_admin, elevated_membership)
    end

    it 'forbids Partner Admins from blanking out the role' do
      blanked_membership = team.memberships.build(role_name: nil)
      expect(described_class).to_not permit(partner_admin, blanked_membership)
    end
  end

  permissions :destroy? do
    it 'allows login.gov admins' do
      expect(described_class).to permit(logingov_admin, partner_admin_membership)
    end

    it 'allows login.gov admins to delete their own membership' do
      admin_team_membership = create(
        :membership,
        user: logingov_admin,
        team: partner_admin_membership.team,
      )
      expect(described_class).to permit(logingov_admin, admin_team_membership)
    end

    it 'allows Partner Admins on the same team' do
      new_membership = partner_admin_membership.team.memberships.build
      expect(described_class).to permit(partner_admin, new_membership)
    end

    it 'forbids Partner Admins on their own membership' do
      expect(described_class).to_not permit(partner_admin, partner_admin_membership)
    end

    it 'forbids Partner Developers on the same team' do
      new_membership = partner_developer_membership.team.memberships.build
      expect(described_class).to_not permit(partner_developer, new_membership)
    end
  end

  describe '#roles_for_edit' do
    it 'is everything but Login Admin for Login Admins' do
      membership = [partner_admin_membership,
                    partner_developer_membership,
                    partner_readonly_membership].sample
      expected_roles = Role.all - [Role::LOGINGOV_ADMIN]
      expect(described_class.new(logingov_admin, membership).roles_for_edit).to eq(expected_roles)
    end

    it 'is everything but Login Admin and Partner Admin for Partner Admins' do
      membership = [partner_developer_membership, partner_readonly_membership].sample
      expected_roles = Role.all - [Role::LOGINGOV_ADMIN, Role.find_by(name: 'partner_admin')]
      expect(described_class.new(partner_admin, membership).roles_for_edit).to eq(expected_roles)
    end

    it 'is empty for Partner Admins when trying to edit themselves' do
      expect(described_class.new(partner_admin, partner_admin_membership).roles_for_edit).to eq([])
    end

    it 'is empty for memberships for teams the Partner Admin is not on' do
      different_team_membership = build(:membership)
      expect(described_class.new(partner_admin, different_team_membership).roles_for_edit).to eq([])
    end

    it 'is empty for everyone else' do
      roles_when_dev_edits_readonly = described_class.new(
        partner_developer,
        partner_readonly_membership,
      ).roles_for_edit
      expect(roles_when_dev_edits_readonly).to eq([])
      roles_when_readonly_edits_dev = described_class.new(
        partner_readonly,
        partner_developer_membership,
      ).roles_for_edit
      expect(roles_when_readonly_edits_dev).to eq([])
    end
  end
end
