require 'rails_helper'

describe ManageUsersForm do
  let(:team) { create(:team) }
  let(:user_already_on_the_team) { create(:user, teams: [team]) }
  let(:user_not_already_on_the_team) { create(:user) }
  let(:email_for_nonexistent_user) { 'NonExistent@gsa.gov' }

  let(:user_emails) do
    [
      user_not_already_on_the_team.email.upcase,
      email_for_nonexistent_user,
    ]
  end

  subject { described_class.new(team) }

  describe '#submit' do
    it 'creates users that do not exist and adds users to the team' do
      result = subject.submit(user_emails: user_emails)

      previously_nonexistent_user = User.find_by(email: email_for_nonexistent_user.downcase)
      team_users = team.reload.users

      expect(result).to eq(true)
      expect(subject.errors).to be_empty
      expect(team_users).to include(user_already_on_the_team)
      expect(team_users).to include(user_not_already_on_the_team)
      expect(previously_nonexistent_user).to_not be_nil
      expect(team_users).to include(previously_nonexistent_user)
    end

    context 'when some of the email addresses are not valid emails' do
      it 'returns false and has errors for each invalid email' do
        result = subject.submit(user_emails: user_emails + ['invalid', 'not valid'])

        previously_nonexistent_user = User.find_by(email: email_for_nonexistent_user)
        team_users = team.reload.users

        expect(result).to eq(false)
        expect(subject.errors[:base]).to include('invalid is not a valid email address')
        expect(subject.errors[:base]).to include('not valid is not a valid email address')
        expect(team_users).to include(user_already_on_the_team)
        expect(team_users).to_not include(user_not_already_on_the_team)
        expect(previously_nonexistent_user).to be_nil
      end
    end


    context 'when adding user that already exists on team' do
      it 'returns false and throws validation error' do
        expect { subject.submit(user_emails: user_emails + [user_already_on_the_team.email]) }.to \
        raise_error { ActiveRecord::RecordInvalid }

        previously_nonexistent_user = User.find_by(email: email_for_nonexistent_user.downcase)
        team_users = team.reload.users
 
        expect(team_users).to include(user_already_on_the_team)
        expect(team_users).to_not include(user_not_already_on_the_team)
        expect(previously_nonexistent_user).to be_nil
      end
    end

    context 'when no emails addresses are submitted' do
      it 'returns false and has a general error message' do
        result = subject.submit(user_emails: [])

        expect(result).to eq(false)
        expect(subject.errors[:base]).to include('You must submit at least one email address')
      end
    end

    context 'when the team fails to save' do
      let(:team) { Team.new(name: nil) }
      let(:user_emails) do
        [
          'emails_that___@gsa.gov',
          'dont_trigger__@gsa.gov',
          'a_save________@gsa.gov',
        ]
      end

      it 'returns false and has the teams errors' do
        result = subject.submit(user_emails: user_emails)

        expect(result).to eq(false)
        expect(subject.errors[:name]).to include("can't be blank")
      end
    end
  end
end
