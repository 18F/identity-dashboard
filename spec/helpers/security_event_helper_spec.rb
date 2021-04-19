require 'rails_helper'

RSpec.describe SecurityEventHelper do
  describe '#friendly_name' do
    it 'is the last segment of the URL' do
      security_event = build(:security_event, event_type: 'https://.../some-unknown-event')

      expect(friendly_name(security_event)).to eq('some-unknown-event')
    end
  end
end
