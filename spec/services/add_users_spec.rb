require 'rails_helper'

describe AddUsers do
  let(:team) { create(:team) }
  let(:user_already_on_the_team) { create(:user, teams: [team]) }
  let(:user_not_already_on_the_team) { create(:user) }
  let(:email_for_nonexistant_user) { 'nonexistant@gsa.gov' }

  let(:user_emails) do
    [
      user_already_on_the_team.email,
      user_not_already_on_the_team.email,
      email_for_nonexistant_user,
    ]
  end

  subject { described_class.new(team: team, user_emails: user_emails) }

  describe '#call' do
    it 'creates users that do not exist and adds users to the team' do
      subject.call

      previously_nonexistant_user = User.find_by(email: email_for_nonexistant_user)
      team_users = team.reload.users

      expect(team_users).to include(user_already_on_the_team)
      expect(team_users).to include(user_not_already_on_the_team)
      expect(previously_nonexistant_user).to_not be_nil
      expect(team_users).to include(previously_nonexistant_user)
    end
  end
end
