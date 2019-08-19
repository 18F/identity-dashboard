class ServiceProviderUpdater
  # :reek:TooManyStatements
  def self.ping
    resp = HTTParty.post(idp_url, headers: token_header)
    status_code = resp.code
    return status_code if status_code == 200

    handle_error(status_code)
  rescue StandardError => error
    handle_error(error.msg)
  end

  class <<self
    def idp_url
      Figaro.env.idp_sp_url
    end

    def token_header
      { 'X-LOGIN-DASHBOARD-TOKEN' => Figaro.env.dashboard_api_token }
    end

    def handle_error(status)
      ::NewRelic::Agent.notice_error("ServiceProviderUpdater failed with "\
        "status: #{status}")
      status
    end
  end
end
