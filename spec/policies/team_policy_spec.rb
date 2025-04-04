require 'rails_helper'

describe TeamPolicy do
  let(:logingov_admin) { build(:logingov_admin) }
  let(:team_user) { build(:user) }
  let(:gov_email_user) { build(:user) }
  let(:nongov_email_user) { build(:user, email: 'user@example.com') }
  let(:team) { create(:team) }
  let(:partner_admin_user) { create(:user_team, :partner_admin, team:).user }
  let(:partner_developer_user) { create(:user_team, :partner_developer, team:).user }
  let(:partner_readonly_user) { create(:user_team, :partner_readonly, team:).user }

  before do
    team.users << team_user
  end

  before do
    allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(true)
  end

  context 'users with gov email addresses' do
    permissions :create? do
      context 'users with gov email addresses' do
        it 'who are login.gov admins or partner admins are allowed to create their team' do
          expect(TeamPolicy).to permit(logingov_admin, team)
          expect(TeamPolicy).to permit(partner_admin_user, team)
        end

        context 'if they are admins' do
          before { gov_email_user.update(admin: true) }

          it 'are allowed to create teams' do
            expect(TeamPolicy).to permit(gov_email_user)
          end
        end
      end
    end

    permissions :edit? do
      context 'team members' do
        it 'who are partner admins are allowed to edit their team' do
          expect(TeamPolicy).to permit(partner_admin_user, team)
        end
        it 'who are not partner admins are not allowed to edit their team' do
          expect(TeamPolicy).to_not permit(team_user, team)
          expect(TeamPolicy).to_not permit(partner_readonly_user, team)
          expect(TeamPolicy).to_not permit(partner_developer_user, team)
        end
      end

      context 'login.gov admins' do
        it 'are allowed to edit any team' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end
      end
    end

    permissions :update? do
      context 'team members' do
        it 'who are partner admins are allowed to update their team' do
          expect(TeamPolicy).to permit(partner_admin_user, team)
        end
        it 'who are not partner admins are not allowed to update their team' do
          expect(TeamPolicy).to_not permit(team_user, team)
          expect(TeamPolicy).to_not permit(partner_readonly_user, team)
          expect(TeamPolicy).to_not permit(partner_developer_user, team)
        end
      end

      context 'login.gov admins' do
        it 'are allowed to update any team' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end
      end
    end

    permissions :new? do
      context 'users with gov email addresses' do
        it 'login.gov admins can initiate team creation' do
          expect(TeamPolicy).to permit(logingov_admin)
        end
      end
    end

    permissions :destroy? do
      context 'login.gov admins' do
        it 'can destroy teams' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end
      end

      context 'partner admin users' do
        it 'cannot destroy teams' do
          expect(TeamPolicy).to_not permit(partner_admin_user, team)
        end
      end

      context 'team users' do
        it 'cannot destroy teams' do
          expect(TeamPolicy).to_not permit(team_user, team)
        end
      end
    end

    permissions :show? do
      context 'login.gov admins' do
        it 'can look at any team' do
          expect(TeamPolicy).to permit(logingov_admin, team)
        end
      end

      context 'team users' do
        it 'can look at their teams' do
          expect(TeamPolicy).to permit(team_user, team)
        end
      end
    end

    permissions :all? do
      context 'login.gov admins' do
        it 'can view all teams' do
          expect(TeamPolicy).to permit(logingov_admin)
        end
      end

      context 'users with gov email addresses' do
        it 'cannot view all teams' do
          expect(TeamPolicy).to_not permit(gov_email_user)
        end
      end
    end
  end

  context 'users with non gov email addresses' do
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
    end

    permissions :edit? do
      context 'non team members' do
        it 'are not allowed to edit the team' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end
    end

    permissions :update? do
      context 'non team members' do
        it 'are not allowed to update the team' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end

    end

    permissions :new? do
      context 'users with non gov email address with RBAC enabled' do
        it 'cannot initiate team creation' do
          expect(TeamPolicy).to_not permit(nongov_email_user)
        end

        context 'login.gov admins' do
          before { logingov_admin.update(email: 'user@examle.com') }

          it 'can initiate team creation' do
            expect(TeamPolicy).to permit(logingov_admin)
          end
        end
      end
      context 'users with non gov email address with RBAC disabled' do
        before do
          allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return(false)
        end

        it 'cannot initiate team creation' do
          expect(TeamPolicy).to_not permit(nongov_email_user)
        end
      end
    end

    permissions :destroy? do
      context 'random users' do
        it 'cannot destroy teams' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end
    end

    permissions :show? do
      context 'random users' do
        it 'cannot look at a team they are not a part of' do
          expect(TeamPolicy).to_not permit(nongov_email_user, team)
        end
      end
    end

    permissions :all? do
      context 'random users' do
        it 'cannot view all teams' do
          expect(TeamPolicy).to_not permit(nongov_email_user)
        end
      end
    end
  end
end
