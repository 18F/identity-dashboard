require 'rails_helper'

describe TeamPolicy do
  let(:logingov_admin) { build(:logingov_admin) }
  let(:team) { create(:team) }
  let(:other_team) { build(:team) }

  context 'with RBAC on' do
    let(:partner_admin_user) { create(:user_team, :partner_admin, team:).user }
    let(:partner_developer_user) { create(:user_team, :partner_developer, team:).user }
    let(:partner_readonly_user) { create(:user_team, :partner_readonly, team:).user }
    let(:user_not_on_team) { build(:user) }

    before do
      allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
    end

    permissions :create? do
      it 'allows login.gov admins or partner admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(partner_admin_user, team)
      end

      it 'does not allow others' do
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
      end

      context 'in a prod-like env' do
        before do
          allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        end

        it 'allows login.gov admins' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end

        it 'forbids everyone else' do
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
      it 'allows login.gov admins or partner admins' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(partner_admin_user, team)
      end

      it 'does not allow non-admin users' do
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      end

      it 'does not allow partners in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        expect(TeamPolicy).to_not permit(partner_admin_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
      end

      it 'does allow login.gov admins in prod-like envs' do
        allow(IdentityConfig.store).to receive(:prod_like_env).and_return(true)
        expect(TeamPolicy).to permit(logingov_admin, team)
      end
    end

    permissions :destroy? do
      it 'allows logingov admin' do
        expect(TeamPolicy).to permit(logingov_admin, team)
      end

      it 'forbids partners' do
        expect(TeamPolicy).to_not permit(partner_admin_user, team)
        expect(TeamPolicy).to_not permit(user_not_on_team, team)
        expect(TeamPolicy).to_not permit(partner_readonly_user, team)
        expect(TeamPolicy).to_not permit(partner_developer_user, team)
      end
    end

    permissions :show? do
      it 'allows logingov_admin' do
        expect(TeamPolicy).to permit(logingov_admin, team)
        expect(TeamPolicy).to permit(logingov_admin, other_team)
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
      it 'allows login.gov admins' do
        expect(TeamPolicy).to permit(logingov_admin)
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
      user.user_teams.build(team:)
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
        nongov_email_user.user_teams.build(team:)
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
        nongov_email_user.user_teams.build(team:)
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

        it 'allowed if they are a member' do
          nongov_email_user.user_teams.build(team:)
          expect(TeamPolicy).to permit(nongov_email_user, team)
        end
      end
    end

    permissions :all? do
      it 'allows login.gov admins' do
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
