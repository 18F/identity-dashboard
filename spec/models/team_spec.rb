require 'rails_helper'

describe Team do
  describe 'Associations' do
    it { should have_many(:users) }
    it { should have_many(:service_providers) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:name) }

    it 'validates uniqueness of name' do
      name = 'good name'
      create(:team, name: name)
      duplicate = build(:team, name: name)

      expect(duplicate).not_to be_valid
    end
  end

  describe '.sorted' do
    it 'returns users in alpha ordered by email' do
      b_user = create(:user, email: 'b@example.com')
      c_user = create(:user, email: 'c@example.com')
      a_user = create(:user, email: 'a@example.com')

      expect(User.sorted).to eq([a_user, b_user, c_user])
    end
  end

  describe 'paper_trail', versioning: true do
    it { is_expected.to be_versioned }

    it 'tracks creation' do
      expect { create(:team) }.to change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks updates' do
      team = create(:team)

      expect { team.update!(name: 'Team Awesome') }.to change { PaperTrail::Version.count }.by(1)
    end

    it 'tracks deletion' do
      team = create(:team)

      expect { team.destroy }.to change { PaperTrail::Version.count }.by(1)
    end
  end
end
