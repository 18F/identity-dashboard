class ServiceProviderUpdater
  def self.ping
    resp = Faraday.post(idp_url, nil, token_header)

    status_code = resp.status
    return status_code if status_code == 200

    failure = StandardError.new "ServiceProviderUpdater failed with status: #{status_code}"
    handle_error(failure)
    status_code
  rescue StandardError => error
    handle_error(error)
    status_code
  end

  class << self
    def idp_url
      IdentityConfig.store.idp_sp_url
    end

    def token_header
      { 'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token }
    end

    def handle_error(error)
      ::NewRelic::Agent.notice_error(error)
    end
  end
end
