require 'rails_helper'

describe ServiceProviderCertificate do
  before do
    allow(Figaro.env).to receive(:certificate_expiration_warning_period).and_return('5')
  end

  context 'certificate is expired' do
    it 'wraps the expiration in ansi color codes to make it black on red' do
      expired_time = 1.day.ago
      expect(ServiceProviderCertificate.expiration_time_to_colorized_s(expired_time)).
        to match(/\A\e\[0;30;41m#{expired_time.to_s}\e\[0m\z/)
    end
  end
  context 'certificate is near expiration' do
    it 'wraps the expiration in ansi color codes to make it black on yellow' do
      expired_time = (5.days - 10.seconds).from_now
      expect(ServiceProviderCertificate.expiration_time_to_colorized_s(expired_time)).
        to match(/\A\e\[0;30;103m#{expired_time.to_s}\e\[0m\z/)
    end
  end
  context 'certificate is not near expiration' do
    it 'does not wraps the expiration in ansi color codes' do
      expired_time = (5.days + 10.seconds).from_now
      expect(ServiceProviderCertificate.expiration_time_to_colorized_s(expired_time)).
        to match(/\A#{expired_time.to_s}\z/)
    end
  end
end
