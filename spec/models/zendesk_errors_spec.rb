require 'rails_helper'

RSpec.describe ZendeskErrors do
  context 'with no errors' do
    subject { described_class.new([]) }

    it 'returns empty values for array methods' do
      expect(subject.unrecoverable_errors).to eq([])
      expect(subject.user_facing_errors).to eq([])
      expect(subject.messages).to eq([])
    end

    it 'does something' do
      expect(subject.initial_text).to eq('An unknown error occurred.')
      expect(subject.remaining_text).to eq(
        'You can create a request manually through ' \
        '<a href="https://partners.login.gov/hc/en-us/requests/new">this contact form</a> ' \
        'instead.',
      )
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
      expect(subject.initial_text).to eq(
        'Please fix the following problems with your configuration before submitting a request.',
      )
      expect(subject.remaining_text).to eq(
        'Application URL: is invalid. Application Description: is invalid. Please try again.',
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
      expect(subject.initial_text).to eq(
        'We are unable to submit requests through this form right now.',
      )
      expect(subject.remaining_text).to eq(
        'Partner Portal Configuration URL: is invalid. You can create a request manually through ' \
        '<a href="https://partners.login.gov/hc/en-us/requests/new">this contact form</a> instead.',
      )
    end
  end
end
