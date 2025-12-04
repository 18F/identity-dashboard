require 'rails_helper'

describe TeamPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:team) { create(:team) }
  let(:other_team) { build(:team) }

  context 'with RBAC on' do
    let(:logingov_readonly) { create(:logingov_readonly) }
    let(:partner_admin_user) { create(:team_membership, :partner_admin, team:).user }
    let(:partner_developer_user) { create(:team_membership, :partner_developer, team:).user }
    let(:partner_readonly_user) { create(:team_membership, :partner_readonly, team:).user }
    let(:user_not_on_team) { build(:user) }
    let(:gov_partner) { create(:user, email: 'test@agency.gov') }
    let(:mil_partner) { create(:user, email: 'test@branch.mil') }
    let(:contractor) { create(:user, email: 'user@contrator.com') }

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
    end

    permissions :create? do
      it 'allows logingov admins or .gov|mil parters' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(gov_partner, team)
        expect(TeamPolicy).to permit(mil_partner, team)
      end

      it 'does not allow others' do
        expect(TeamPolicy).to_not permit(contractor, team)
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      context 'in a prod-like env' do
        before do
          allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        end

        it 'allows logingov admins' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end

        it 'forbids everyone else' do
          expect(TeamPolicy).to_not permit(logingov_readonly, team)
          expect(TeamPolicy).to_not permit(gov_partner, team)
          expect(TeamPolicy).to_not permit(mil_partner, team)
          expect(TeamPolicy).to_not permit(contractor, team)
          expect(TeamPolicy).to_not permit(user_not_on_team, team)
          expect(TeamPolicy).to_not permit(partner_admin_user, team)
          expect(TeamPolicy).to_not permit(partner_developer_user, team)
          expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        end
      end
    end

    permissions :edit? do
      it 'allows partner admins for their team' do
        expect(TeamPolicy).to permit(partner_admin_user, team)
      end

      it 'denies other non-admin team members' do
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
      end

      it 'denies access to other teams' do
        expect(TeamPolicy).to_not permit(logingov_readonly, other_team)
        expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, other_team)
        expect(TeamPolicy).to_not permit(partner_developer_user, other_team)
      end

      it 'always allows logingov admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(logingov_admin, other_team)
      end
    end

    permissions :update? do
      it 'allows partner admins on the team' do
        expect(TeamPolicy).to permit(partner_admin_user, team)
      end

      it 'forbids users who are not partner admins' do
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
      end

      it 'forbids partner admins from other teams' do
        expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
      end

      it 'allows logingov admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
      end
    end

    permissions :new? do
      it 'allows logingov admins or .gov|mil partners' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(gov_partner, team)
        expect(TeamPolicy).to permit(mil_partner, team)
      end

      it 'does not allow logingov readonly' do
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      it 'does not allow other users' do
        expect(TeamPolicy).to_not permit(contractor, team)
      end

      it 'does not allow partners in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        expect(TeamPolicy).to_not permit(gov_partner, team)
        expect(TeamPolicy).to_not permit(mil_partner, team)
        expect(TeamPolicy).to_not permit(contractor, team)
        expect(TeamPolicy).to_not permit(partner_admin_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      end

      it 'does not allow logingov readonly in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      it 'does allow logingov admins in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        expect(TeamPolicy).to permit(logingov_admin, team)
      end
    end

    permissions :destroy? do
      it 'allows logingov admin' do
        expect(TeamPolicy).to permit(logingov_admin, team)
      end

      it 'forbids logingov readonly' do
        expect(TeamPolicy).to_not permit(logingov_readonly, team)
      end

      it 'forbids partners' do
        expect(TeamPolicy).to_not permit(partner_admin_user, team)
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
      end
    end

    permissions :show? do
      it 'allows logingov staff' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(logingov_admin, other_team)
        expect(TeamPolicy).to permit(logingov_readonly, team)
        expect(TeamPolicy).to permit(logingov_readonly, other_team)
      end

      it 'allows partners on the team' do
        expect(TeamPolicy).to permit(partner_readonly_user, team)
        expect(TeamPolicy).to permit(partner_developer_user, team)
        expect(TeamPolicy).to permit(partner_admin_user, team)
      end

      it 'forbids partners on other teams' do
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, other_team)
        expect(TeamPolicy).to_not permit(partner_developer_user, other_team)
        expect(TeamPolicy).to_not permit(partner_admin_user, other_team)
      end
    end

    permissions :all? do
      it 'allows logingov staff' do
        expect(TeamPolicy).to permit(logingov_admin)
        expect(TeamPolicy).to permit(logingov_readonly)
      end

      it 'denies everyone else' do
        expect(TeamPolicy).to_not permit(user_not_on_team)
        expect(TeamPolicy).to_not permit(partner_readonly_user)
        expect(TeamPolicy).to_not permit(partner_developer_user)
        expect(TeamPolicy).to_not permit(partner_admin_user)
      end
    end
  end

  context 'without RBAC' do
    let(:gov_email_user) do
      user = build(:user)
      user.team_memberships.build(team:)
      user
    end
    let(:nongov_email_user) { build(:user, email: 'user@example.com') }

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
    end

    permissions :create? do
      context 'users with non gov email address' do
        it 'are not allowed to create teams' do
          expect(TeamPolicy).to_not permit(nongov_email_user)
        end

        context 'if they are admins' do
          before { nongov_email_user.update(admin: true) }

          it 'are allowed to create teams' do
            expect(TeamPolicy).to permit(nongov_email_user)
          end
        end
      end

      it 'allows users with gov email addresses' do
        expect(TeamPolicy).to permit(gov_email_user)
      end
    end

    permissions :edit? do
      context 'non team members' do
        it 'are not allowed to edit the team' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end

      it 'allows team members' do
        nongov_email_user.team_memberships.build(team:)
        expect(TeamPolicy).to permit(nongov_email_user, team)
      end
    end

    permissions :update? do
      context 'non team members' do
        it 'are not allowed to update the team' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end

      it 'allows team members' do
        nongov_email_user.team_memberships.build(team:)
        expect(TeamPolicy).to permit(nongov_email_user, team)
      end
    end

    permissions :new? do
      it 'does not allow nongov emails' do
        expect(TeamPolicy).to_not permit(nongov_email_user)
      end

      it 'allows nongov emails if they are logingov admins' do
        nongov_email_user.admin = true
        expect(TeamPolicy).to permit(nongov_email_user)
      end

      it 'does allow gov emails' do
        expect(TeamPolicy).to permit(gov_email_user)
      end
    end

    permissions :destroy? do
      context 'random users' do
        it 'cannot destroy teams' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
          expect(TeamPolicy).to_not permit(gov_email_user, team)
        end
      end

      it 'allows logingov admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
      end
    end

    permissions :show? do
      context 'random users' do
        it 'cannot look at a team they are not a part of' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end

        it 'allowed if they are a team member' do
          nongov_email_user.team_memberships.build(team:)
          expect(TeamPolicy).to permit(nongov_email_user, team)
        end
      end
    end

    permissions :all? do
      it 'allows logingov admins' do
        expect(TeamPolicy).to permit(logingov_admin)
      end

      context 'random users' do
        it 'cannot view all teams' do
          expect(TeamPolicy).to_not permit(nongov_email_user)
          expect(TeamPolicy).to_not permit(gov_email_user)
        end
      end
    end
  end
end
