require 'rails_helper'

describe ReturnTracker do
  let(:simple_store) { {} }
  let(:team) { create(:team) }

  feature 'with an ID parameter' do
    it 'can set and get a specific team path' do
      setter = described_class.new(simple_store, :config)
      setter.set("team,#{team.id}")

      getter = described_class.new(simple_store, :config)
      expect(getter.path).to eq(team_path(team))
    end
  end

  describe 'falls back to defaults' do
    let(:expected_default) { '/service_providers' }
    let(:subject) { described_class.new(simple_store, :config) }

    it 'when given garbage' do
      simple_store['return_config'] = 'alskjdf;soaidfh;aoisdfh;klsjdf'
      expect(subject.path).to eq(expected_default)
    end

    it 'when given an invalid key' do
      simple_store['return_config'] = 'user,1'
      expect(subject.path).to eq(expected_default)
    end

    it 'when given blank' do
      simple_store['return_config'] = ''
      expect(subject.path).to eq(expected_default)
    end

    it 'when given invalid characters in the ID' do
      simple_store['return_config'] = 'team,../../../etc/passwd'
      expect(subject.path).to eq(expected_default)
    end

    it 'given an ID for a key that does not support it' do
      simple_store['return_config'] = 'team_index,1'
      expect(subject.path).to eq(expected_default)
    end
  end
end
