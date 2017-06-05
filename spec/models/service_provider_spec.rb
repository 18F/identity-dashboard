require 'rails_helper'

describe ServiceProvider do
  describe 'Associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:agency) }
  end

  let(:service_provider) { build(:service_provider) }

  describe '#issuer' do
    it 'assigns uuid on create' do
      service_provider.save
      expect(service_provider.issuer).to_not be_nil
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
