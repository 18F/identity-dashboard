require 'rails_helper'

RSpec.describe 'service_providers/_certificate_expiration_td.html.erb' do
  let(:app) { instance_double(ServiceProvider, certificates:) }
  let(:issuer) { OpenSSL::X509::Name.new([['O', 'GSA']]) }

  let(:expired_certificate) do
    ServiceProviderCertificate.new(
      instance_double(OpenSSL::X509::Certificate, not_after: 1.day.ago, issuer: issuer),
    )
  end

  let(:valid_certificate) do
    ServiceProviderCertificate.new(
      instance_double(OpenSSL::X509::Certificate, not_after: 1.year.from_now, issuer: issuer),
    )
  end

  subject(:td_tag) do
    render partial: 'service_providers/certificate_expiration_td', locals: { app: }

    Nokogiri::HTML(rendered).at_css('td')
  end

  context 'with no certificates' do
    let(:certificates) { [] }

    it 'renders a null certificate' do
      expect(td_tag.text.strip).to eq('Invalid')
      expect(td_tag[:class]).to be_blank
    end
  end

  context 'with an expired certificate' do
    let(:certificates) { [expired_certificate] }

    it 'renders an expired certificate' do
      expect(td_tag.text.strip).to eq(expired_certificate.not_after.localtime.strftime('%F'))
      expect(td_tag[:class]).to eq('certificate-expired')
    end
  end

  context 'with multiple certificates' do
    let(:certificates) { [expired_certificate, valid_certificate] }

    it 'renders the one that expires farthest in the future' do
      expect(td_tag.text.strip).to eq(valid_certificate.not_after.localtime.strftime('%F'))
      expect(td_tag[:class]).to be_blank
    end
  end
end