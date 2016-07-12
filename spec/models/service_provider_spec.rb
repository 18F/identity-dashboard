require 'rails_helper'

describe ServiceProvider do
  describe 'Associations' do
    it { should belong_to(:user) }
  end

  let(:service_provider) { build(:service_provider) }

  describe '#issuer' do
    it 'assigns uuid on create' do
      service_provider.save
      expect(service_provider.issuer).to_not be_nil
      expect(service_provider.issuer).to match(RubyRegex::UUID)
    end
  end

  describe '#recently_approved?' do
    it 'detects when flag toggles to true' do
      expect(service_provider.recently_approved?).to eq false
      service_provider.approved = true
      service_provider.save!
      expect(service_provider.recently_approved?).to eq true
    end
  end
end
