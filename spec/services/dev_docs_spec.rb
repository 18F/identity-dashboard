require 'rails_helper'

RSpec.describe DevDocs do
  before { Rails.cache.clear }

  let(:risc_data_url) { URI.join(Figaro.env.dev_docs_url, 'data/risc.json') }

  let(:risc_json) do
    {
      supported_events: [
        {
          friendly_name: 'Identifier Recycled',
          event_type: 'https://schemas.openid.net/secevent/risc/event-type/identifier-recycled',
        },
        {
          friendly_name: 'Account Purged',
          event_type: 'https://schemas.openid.net/secevent/risc/event-type/account-purged',
        },
        {
          friendly_name: 'Recovery Activated',
          event_type: 'https://schemas.openid.net/secevent/risc/event-type/recovery-activated',
          description: 'Some event that does things like XYZ',
        },
      ],
    }
  end

  before do
    stub_request(:get, risc_data_url).
      to_return(body: risc_json.to_json)
  end

  describe '.risc_events' do
    let(:event_type) { 'https://schemas.openid.net/secevent/risc/event-type/identifier-recycled' }

    it 'is a hash of event_type => RiscEvent struct' do
      expect(DevDocs.risc_events).to be_a(Hash)
      expect(DevDocs.risc_events[event_type]).to be_a(DevDocs::RiscEvent)
    end

    it 'caches the network request' do
      3.times { DevDocs.risc_events }

      expect(a_request(:get, risc_data_url)).to have_been_made.once
    end
  end

  describe '.find_risc_event' do
    let(:event_type) { 'https://schemas.openid.net/secevent/risc/event-type/identifier-recycled' }

    it 'looks up events by event_type' do
      expect(DevDocs.find_risc_event(event_type)).to eq(DevDocs::RiscEvent.new(
        friendly_name: 'Identifier Recycled',
        event_type: 'https://schemas.openid.net/secevent/risc/event-type/identifier-recycled',
      ))
    end
  end

  subject(:dev_docs) { DevDocs.new }

  describe '#load_risc_events' do
    subject(:load_risc_events) { dev_docs.load_risc_events }

    context 'with a network error' do
      before do
        stub_request(:get, risc_data_url).to_timeout
      end

      it 'logs a warning and returns an empty array' do
        expect(Rails.logger).to receive(:warn)

        expect(load_risc_events).to eq([])
      end
    end

    context 'when the endpoint 404s' do
      before do
        stub_request(:get, risc_data_url).
          to_return(status: 404, body: '<html />')
      end

      it 'logs a warning and returns an empty array' do
        expect(Rails.logger).to receive(:warn)

        expect(load_risc_events).to eq([])
      end
    end

    context 'when the endpoint has an unexpected data shape' do
      before do
        stub_request(:get, risc_data_url).
          to_return(body: { foo_bar: true }.to_json)
      end

      it 'returns an empty array' do
        expect(load_risc_events).to eq([])
      end
    end

    context 'when the endpoint has new unknown attributes' do
      before do
        stub_request(:get, risc_data_url).
          to_return(body: risc_json.to_json)
      end

      let(:risc_json) do
        {
          supported_events: [
            some_new_key: 'aaaa',
            event_type: '/identifier-recycled',
            friendly_name: 'Identifier Recycled',
          ],
        }
      end

      it 'ignores them' do
        expect(load_risc_events.first).to eq(DevDocs::RiscEvent.new(
          event_type: '/identifier-recycled',
          friendly_name: 'Identifier Recycled',
        ))
      end
    end
  end
end