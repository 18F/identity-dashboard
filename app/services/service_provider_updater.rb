class ServiceProviderUpdater
  def ping
    resp = HTTParty.post(idp_url, headers: token_header)
    resp.code == 200
  end

  private

  def idp_url
    Figaro.env.idp_sp_url
  end

  def token_header
    { 'X-LOGIN-DASHBOARD-TOKEN' => Figaro.env.dashboard_api_token }
  end
end
