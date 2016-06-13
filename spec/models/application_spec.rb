require 'rails_helper'

describe Application do
  describe 'Associations' do
    it { should belong_to(:user) }
  end

  let(:application) { build(:application) }

  describe '#issuer' do
    it 'assigns uuid on create' do
      application.save
      expect(application.issuer).to_not be_nil
      expect(application.issuer).to match(RubyRegex::UUID)
    end
  end

  describe '#recently_approved?' do
    it 'detects when flag toggles to true' do
      expect(application.recently_approved?).to eq false
      application.approved = true
      application.save!
      expect(application.recently_approved?).to eq true
    end
  end
end
