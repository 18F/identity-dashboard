require 'rails_helper'

RSpec.describe 'service_providers/_certificate.html.erb' do
  let(:expiration) { 1.year.from_now }

  let(:certificate) do
    ServiceProviderCertificate.new(
      instance_double(OpenSSL::X509::Certificate,
        not_after: expiration,
        issuer: OpenSSL::X509::Name.new([['O', 'TTS'], ['C', 'US']]),
        subject: OpenSSL::X509::Name.new([['O', 'GSA'], ['C', 'US']]),
        serial: OpenSSL::BN.new(SecureRandom.rand(100_000)),
        to_pem: "----BEGIN CERTIFICATE-----\nI AM A PEM\n----END CERTIFICATE----"),
    )
  end

  subject(:render_view) do
    render 'service_providers/certificate', certificate:
  end

  it 'renders the issuer, subject, and serial number' do
    render_view

    expect(rendered).
      to have_css("dt:contains('Issuer') + dd:contains('#{certificate.issuer}')")
    expect(rendered).
      to have_css("dt:contains('Subject') + dd:contains('#{certificate.subject}')")
    expect(rendered).
      to have_css("dt:contains('Serial Number') + dd:contains('#{certificate.serial}')")
  end

  it 'renders the PEM inside a details/summary block' do
    render_view

    doc = Nokogiri::HTML(rendered)

    details = doc.at_css('details')
    expect(details.at_css('> summary')).to be

    pre_code = details.at_css('> pre > code')
    expect(pre_code.text).to eq(certificate.to_pem)
  end

  context 'with an expired certificate' do
    let(:expiration) { 1.day.ago }

    it 'renders the expired certificate' do
      render_view

      expect(rendered).to have_css('dd .certificate-expired')
    end
  end

  it 'renders the contents of the block (if given) inside the card' do
    render('service_providers/certificate', certificate:) do
      <<-HTML.html_safe
        <div id="from-block">
      HTML
    end

    expect(rendered).to have_css('.lg-card > #from-block')
  end
end