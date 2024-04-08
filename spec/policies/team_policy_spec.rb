require 'rails_helper'

describe TeamPolicy do
  let(:admin_user) { create(:admin) }
  let(:team_user) { create(:restricted_ic, :with_teams) }
  let(:gov_email_user) { create(:ic) }
  let(:nongov_email_user) { create(:restricted_ic) }
  let(:team) { team_user.teams.first }

  permissions :create? do
    context 'users with gov email addresses' do
      it 'admin users are allowed to create teams' do
        expect(TeamPolicy).to permit(admin_user)
      end

      it 'are allowed to create teams' do
        expect(TeamPolicy).to permit(gov_email_user)
      end
    end

    context 'users with non gov email address' do
      it 'are not allowed to create teams' do
        expect(TeamPolicy).to_not permit(nongov_email_user)
      end

      context 'if they are admins' do
        before { admin_user.update(email: 'user@examle.com') }

        it 'are allowed to create teams' do
          expect(TeamPolicy).to permit(admin_user)
        end
      end
    end
  end

  permissions :edit? do
    context 'team members' do
      it 'are allowed to edit their team' do
        expect(TeamPolicy).to permit(team_user, team)
      end
    end

    context 'admins' do
      it 'are allowed to edit any team' do
        expect(TeamPolicy).to permit(admin_user, team)
      end
    end

    context 'non team members' do
      it 'are not allowed to edit the team' do
        expect(TeamPolicy).to_not permit(nongov_email_user, team)
      end
    end
  end

  permissions :update? do
    context 'team members' do
      it 'are allowed to update their team' do
        expect(TeamPolicy).to permit(team_user, team)
      end
    end

    context 'admins' do
      it 'are allowed to update any team' do
        expect(TeamPolicy).to permit(admin_user, team)
      end
    end

    context 'non team members' do
      it 'are not allowed to update the team' do
        expect(TeamPolicy).to_not permit(nongov_email_user, team)
      end
    end
  end

  permissions :new? do
    context 'users with gov email addresses' do
      it 'admin users can initiate team creation' do
        expect(TeamPolicy).to permit(admin_user)
      end

      it 'can initiate team creation' do
        expect(TeamPolicy).to permit(gov_email_user)
      end
    end

    context 'users with non gov email address' do
      it 'cannot initiate team creation' do
        expect(TeamPolicy).to_not permit(nongov_email_user)
      end

      context 'admins' do
        before { admin_user.update(email: 'user@examle.com') }

        it 'can initiate team creation' do
          expect(TeamPolicy).to permit(admin_user)
        end
      end
    end
  end

  permissions :destroy? do
    context 'admins' do
      it 'can destroy teams' do
        expect(TeamPolicy).to permit(admin_user, team)
      end
    end

    context 'team users' do
      it 'cannot destroy teams' do
        expect(TeamPolicy).to_not permit(team_user, team)
      end
    end

    context 'random users' do
      it 'cannot destroy teams' do
        expect(TeamPolicy).to_not permit(nongov_email_user, team)
      end
    end
  end

  permissions :show? do
    context 'admins' do
      it 'can look at any team' do
        expect(TeamPolicy).to permit(admin_user, team)
      end
    end

    context 'team users' do
      it 'can look at their teams' do
        expect(TeamPolicy).to permit(team_user, team)
      end
    end

    context 'random users' do
      it 'cannot look at a team they are not a part of' do
        expect(TeamPolicy).to_not permit(nongov_email_user, team)
      end
    end
  end

  permissions :all? do
    context 'admins' do
      it 'can view all teams' do
        expect(TeamPolicy).to permit(admin_user)
      end
    end

    context 'users with gov email addresses' do
      it 'cannot view all teams' do
        expect(TeamPolicy).to_not permit(gov_email_user)
      end
    end

    context 'random users' do
      it 'cannot view all teams' do
        expect(TeamPolicy).to_not permit(nongov_email_user)
      end
    end
  end
end
