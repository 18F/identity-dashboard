class ServiceProviderUpdater
  def ping
    resp = HTTParty.post(idp_url, headers: token_header)
    resp.code == 200
  end

  private

  def idp_url
    ENV['IDP_SP_URL'] || 'https://login.gov/api/service_provider'
  end

  def token_header
    { 'X-LOGIN-DASHBOARD-TOKEN' => ENV['LOGIN_DASHBOARD_TOKEN'] }
  end
end
