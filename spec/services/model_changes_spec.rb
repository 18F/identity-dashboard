require 'rails_helper'

describe ModelChanges do
  include ModelChanges
  let(:friendly_name) { 'friendly name' }
  let(:record) { create(:service_provider, friendly_name:) }

  describe 'when it is a new record' do
    before do
      allow(record).to receive(:changes).and_return({})
    end

    it 'returns all attributes' do
      expect(changes_to_log(record)).to eq(
        record.as_json
        .merge('id' => record.id),
      )
    end
  end

  describe 'when it is an existing record with pending changes' do
    let(:new_name) { 'new name' }

    it 'returns the pending changes before save' do
      # Assign attributes without saving to test pending changes
      record.friendly_name = new_name
      attrs = {
        'friendly_name' => {
          'old' => friendly_name,
          'new' => new_name,
        },
        'id' => record.id,
      }

      expect(changes_to_log(record)).to eq(attrs)
    end
  end
end
