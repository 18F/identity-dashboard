class ServiceProviderIssuerBuilder
  ISSUER_TEMPLATE = 'urn:gov:gsa:%<protocol>s.profiles:sp:sso:%<department>s:%<app>s'.freeze

  attr_reader :service_provider

  def initialize(service_provider)
    @service_provider = service_provider
  end

  def build_issuer
    format(
      ISSUER_TEMPLATE,
      protocol: protocol_substring,
      department: service_provider.issuer_department,
      app: service_provider.issuer_app
    )
  end

  private

  def protocol_substring
    if service_provider.identity_protocol == 'openid_connect'
      'openidconnect'
    elsif service_provider.identity_protocol == 'saml'
      'SAML:2.0'
    end
  end
end
