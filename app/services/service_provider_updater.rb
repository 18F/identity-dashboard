class ServiceProviderUpdater
  def ping
    resp = HTTParty.post(idp_url, headers: token_header)
    resp.code == 200
  end

  private

  def idp_url
    Figaro.env.IDP_SP_URL
  end

  def token_header
    { 'X-LOGIN-DASHBOARD-TOKEN' => Figaro.env.LOGIN_DASHBOARD_TOKEN }
  end
end
