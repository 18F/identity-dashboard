require 'rails_helper'

RSpec.describe ZendeskErrors do
  context 'with no errors' do
    subject { described_class.new([]) }

    it 'returns empty values for array methods' do
      expect(subject.unrecoverable_errors).to eq([])
      expect(subject.user_facing_errors).to eq([])
      expect(subject.messages).to eq([])
    end

    it 'returns some message in case of a failure state with no known errors' do
      expect(subject.initial_text).to eq('errors.zendesk.unknown')
      expect(subject.remaining_text).to eq(['errors.zendesk.try_manually_html'])
    end
  end

  context 'with recoverable errors' do
    subject do
      described_class.new(
        [
          { 'description' => 'Application URL: is invalid' },
          { 'description' => 'Application Description: is invalid' },
        ],
      )
    end

    it 'returns no unrecoverable errors' do
      expect(subject.unrecoverable_errors).to eq([])
    end

    it 'returns recoverable error information' do
      expect(subject.user_facing_errors).to eq(['Application URL: is invalid',
                                                'Application Description: is invalid'])
      expect(subject.messages).to eq(['Application URL: is invalid',
                                      'Application Description: is invalid'])
      expect(subject.initial_text).to eq('errors.zendesk.service_provider_fix')
      expect(subject.remaining_text).to eq(
        [
          'Application URL: is invalid',
          'Application Description: is invalid',
          'errors.zendesk.try_again',
        ],
      )
    end
  end

  context 'with recoverable errors and an unrecoverable error' do
    subject do
      described_class.new(
        [
          { 'description' => 'Application URL: is invalid' },
          { 'description' => 'Application Description: is invalid' },
          { 'description' => 'Partner Portal Configuration URL: is invalid' },
        ],
      )
    end

    it 'returns no recoverable errors' do
      expect(subject.user_facing_errors).to eq([])
    end

    it 'returns unrecoverable error information' do
      expect(subject.unrecoverable_errors).to eq(['Partner Portal Configuration URL: is invalid'])
      expect(subject.messages).to eq(['Partner Portal Configuration URL: is invalid'])
      expect(subject.initial_text).to eq('errors.zendesk.unavailable')
      expect(subject.remaining_text).to eq(
        ['Partner Portal Configuration URL: is invalid', 'errors.zendesk.try_manually_html'],
      )
    end
  end
end
