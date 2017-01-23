require 'rails_helper'

describe ServiceProviderUpdater do
  describe '#ping' do
    it 'returns true for success' do
      expect(subject.ping).to eq true
    end
  end
end
