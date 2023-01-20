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
        'id'=>1,
        'user_id'=>2,
        'group_id'=>3,
        'removed_at'=>'2021-06-08T17:34:06Z',
        'whodunnit_id'=>'1',
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
    it 'returns user created sps and the users team sps' do
      team = create(:team)
      user.teams = [team]
      user.save
      user_sp = create(:service_provider, user: user)
      team_sp = create(:service_provider, team: team)
      create(:service_provider)
      sorted_sps = [user_sp, team_sp].sort_by { |x| x.friendly_name.downcase }
      expect(user.scoped_service_providers).to eq(sorted_sps)
    end
    it "alphabetizes the list of user created and the user's team sps" do
      team = create(:team)
      user.teams = [team]
      user.save
      sp = {}
      %i[a G c I e].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     user: user, friendly_name: "#{prefix}_service_provider")
      end
      %i[f B h D j].shuffle.each do |prefix|
        sp[prefix.downcase] = create(:service_provider,
                                     team: team, friendly_name: "#{prefix}_service_provider")
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
      user.admin = true
      user.save

      expect(user.scoped_teams).to eq(Team.all)
    end
  end

  describe 'validates' do
    it 'uniqueness of email address' do
      email = 'joe@gsa.gov'
      user.email = email
      user.save
      expect(user).to be_valid
      user_with_same_email = User.new(email: email)
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
end
