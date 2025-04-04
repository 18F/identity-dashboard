require 'rails_helper'

RSpec.describe ServiceProviderCertificate do
  before do
    allow(IdentityConfig.store).to receive(:certificate_expiration_warning_period).and_return(5)
  end

  let(:plain_cert) do
    instance_double(OpenSSL::X509::Certificate, not_after:)
  end

  subject(:cert) do
    ServiceProviderCertificate.new(plain_cert)
  end

  context 'certificate is expired' do
    let(:not_after) { 1.day.ago }

    it 'wraps the expiration in ansi color codes to make it black on red' do
      expect(cert.expiration_time_to_colorized_s).
        to match(/\A\e\[0;30;41m#{not_after.to_s}\e\[0m\z/)
    end

    it 'has an expired CSS style' do
      expect(cert.expiration_css_class).to eq('certificate-expired')
    end
  end

  context 'certificate is near expiration' do
    let(:not_after) { (5.days - 10.seconds).from_now }

    it 'wraps the expiration in ansi color codes to make it black on yellow' do
      expect(cert.expiration_time_to_colorized_s).
        to match(/\A\e\[0;30;103m#{not_after.to_s}\e\[0m\z/)
    end

    it 'has a warning CSS style' do
      expect(cert.expiration_css_class).to eq('certificate-warning')
    end
  end

  context 'certificate is not near expiration' do
    let(:not_after) { (5.days + 10.seconds).from_now }

    it 'does not wrap the expiration in ansi color codes' do
      expect(cert.expiration_time_to_colorized_s).
        to match(/\A#{not_after.to_s}\z/)
    end

    it 'does not have a CSS style' do
      expect(cert.expiration_css_class).to be_nil
    end
  end
end
