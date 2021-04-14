require 'rails_helper'

RSpec.describe SecurityEventHelper do
  before do
    allow(DevDocs).to receive(:risc_events).and_return(
      'https://.../identifier-recycled' => DevDocs::RiscEvent.new(
        friendly_name: 'Identifier Recycled'
      ),
      'https://.../recovery-activated' => DevDocs::RiscEvent.new(
        friendly_name: 'Recovery Activated',
        description: 'Some event that does things like XYZ',
      )
    )
  end

  describe '#friendly_name' do
    it 'is the friendly name when DevDocs has one' do
      security_event = build(:security_event, event_type: 'https://.../identifier-recycled')

      expect(friendly_name(security_event)).to eq('Identifier Recycled')
    end

    it 'falls back to the last segment of the URL' do
      security_event = build(:security_event, event_type: 'https://.../some-unknown-event')

      expect(friendly_name(security_event)).to eq('some-unknown-event')
    end
  end

  describe '#event_description' do
    it 'is the description when DevDocs has one' do
      security_event = build(:security_event, event_type: 'https://.../recovery-activated')

      expect(event_description(security_event)).to eq('Some event that does things like XYZ')
    end

    it 'falls back to nil' do
      security_event = build(:security_event, event_type: 'https://.../identifier-recycled')

      expect(event_description(security_event)).to be_nil
    end
  end
end
