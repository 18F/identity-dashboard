require 'rails_helper'

describe User do
  include MailerSpecHelper

  describe 'Associations' do
    it { should have_many(:service_providers) }
    it { should have_many(:security_events) }
  end

  let(:user) { build(:user) }

  describe '#uuid' do
    it 'does not assign uuid on create' do
      user.save
      expect(user.uuid).to be_nil
    end
  end

  describe '#after_create' do
    it 'does not send welcome email' do
      deliveries.clear
      expect(deliveries.count).to eq(0)
      user.save
      expect(deliveries.count).to eq(0)
    end
  end

  describe '#user_deletion_history', versioning: true do
    it 'returns user deletion_history from paper_trail' do
      team = create(:team)
      user_team = create(:user_team)
      user_team.destroy
      deletion_history = user_team.user.user_deletion_history
      expect(deletion_history.count).to eq(1)
    end
  end

  describe '#user_deletion_report_item' do
    it 'returns formated record from user_deletion_history' do
      user.save
      history_record = {
        'id' => 1,
        'user_id' => 2,
        'group_id' => 3,
        'removed_at' => '2021-06-08T17:34:06Z',
        'whodunnit_id' => '1',
      }
      report_item = user.user_deletion_report_item(history_record)
      expect(report_item[:user_id]).to eq(2)
    end
  end

  describe '#user_deletion_history_report', versioning: true do
    it 'returns deletion history for user' do
      team = create(:team)
      user_team = create(:user_team)
      user = user_team.user
      user_team.destroy
      deletion_report = user.user_deletion_history_report
      expect(deletion_report.first[:user_id]).to eq(user.id)
    end
  end

  describe '#scoped_service_providers' do
    it 'returns only the users team sps regardless of who created them' do
      team = create(:team)
      user.teams = [team]
      user.save
      team_sp = create(:service_provider, team:)
      user_and_team_sp = create(:service_provider, user:, team:)
      _user_only_sp = create(:service_provider, user:)
      _neither_sp = create(:service_provider)
      sorted_sps = [team_sp, user_and_team_sp].sort_by { |x| x.friendly_name.downcase }
      expect(user.scoped_service_providers).to eq(sorted_sps)
    end

    it "alphabetizes the list user's team sps" do
      team = create(:team)
      user.teams = [team]
      user.save
      sp = {}
      %i[a G c I e].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     user: user,
                                     team: team,
                                     friendly_name: "#{prefix}_service_provider")
      end
      %i[f B h D j].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     team: team,
                                     friendly_name: "#{prefix}_service_provider")
      end
      expect(user.scoped_service_providers).to eq(sp.keys.sort.map { |k| sp[k] })
    end
  end

  describe '#scoped_teams' do
    it 'returns collection of users user teams' do
      team = create(:team)
      user.teams = [team]
      user.save

      expect(user.scoped_teams).to eq([team])
    end

    it 'returns all user teams for admins' do
      2.times do
        create(:team)
      end
      user = create(:user, :logingov_admin)

      expect(user.scoped_teams).to eq(Team.all)
    end
  end

  describe 'validates' do
    it 'uniqueness of email address' do
      email = 'joe@gsa.gov'
      user.email = email
      user.save
      expect(user).to be_valid
      user_with_same_email = User.new(email:)
      user_with_same_email.save
      expect(user_with_same_email).not_to be_valid
      user.destroy
      user_with_same_email.save
      expect(user_with_same_email).to be_valid
    end

    it 'validity of email address' do
      valid_email = 'joe@gsa.gov'
      invalid_email = 'invalid'
      user.email = invalid_email
      user.save
      expect(user).to be_invalid
      user.email = valid_email
      user.save
      expect(user).to be_valid
    end
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      expect { create(:user) }.to change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      user = create(:user)

      expect { user.update!(admin: true) }.to change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      user = create(:user)

      expect { user.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end

  describe '#unconfirmed?' do
    it 'returns true if the user is has missed the sign-in deadline' do
      user.created_at = 15.days.ago
      expect(user.unconfirmed?).to be true
    end

    it 'returns false if the user is has not missed the sign-in deadline' do
      user.created_at = 2.days.ago
      expect(user.unconfirmed?).to be false
    end
  end

  describe '#primary_role' do
    it 'returns Partner Admin if the user has no teams yet' do
      expect(user.primary_role.friendly_name).to eq('Partner Admin')
    end

    it 'returns "Login.gov Admin" if the admin boolean is set' do
      user = build(:user, admin: true)
      expect(user.primary_role.friendly_name).to eq('Login.gov Admin')
    end

    it 'returns Partner Readonly if user belongs to teams without role defined' do
      create(:user_team, user:)
      create(:user_team, user:)
      expect(user.primary_role.name).to eq('partner_readonly')
    end

    it 'otherwise returns the role from the first team' do
      user = create(:user, :with_teams)
      first_team = user.user_teams.first
      expected_role = Role.find_by(name: ['logingov_admin', 'partner_admin'].sample)
      first_team.role = expected_role
      first_team.save
      expect(user.primary_role).to eq(expected_role)
    end
  end

  describe '#admin?' do
    it 'is deprecated' do
      default_behavior = User::DeprecateAdmin.deprecator.behavior
      User::DeprecateAdmin.deprecator.behavior = :raise
      expect { User.new.admin? }.to raise_error(ActiveSupport::DeprecationException)
      User::DeprecateAdmin.deprecator.behavior = default_behavior
    end
  end

  describe '#logingov_admin?' do
    it 'is not deprecated' do
      default_behavior = User::DeprecateAdmin.deprecator.behavior
      User::DeprecateAdmin.deprecator.behavior = :raise
      expect { User.new.logingov_admin? }.to_not raise_error
      User::DeprecateAdmin.deprecator.behavior = default_behavior
    end
  end

  describe '#auth_token' do
    it 'always picks the latest one' do
      user.save
      _first_token_record = create(:auth_token, user:)
      second_token_record = create(:auth_token, user:)
      expect(user.auth_token).to eq(second_token_record)
      expect(user.auth_token.ephemeral_token).to be_blank

    end
    it 'builds a new one if none exists' do
      new_token = user.auth_token
      expect(new_token).to_not be_persisted
      expect(new_token.ephemeral_token).to_not be_blank
    end
  end
end
