class ServiceProviderUpdater
  def ping
    resp = HTTParty.post(idp_url)
    resp.code == 200
  end

  private

  def idp_url
    ENV['IDP_SP_URL'] || 'https://login.gov/api/service_provider'
  end
end
