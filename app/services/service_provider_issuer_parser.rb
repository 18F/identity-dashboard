class ServiceProviderIssuerParser
  attr_reader :issuer

  def initialize(issuer)
    @issuer = issuer
  end

  def parse
    ServiceProvider::ISSUER_FORMAT_REGEXP.match(issuer) || {}
  end
end
