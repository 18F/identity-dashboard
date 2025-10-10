# Writes ServiceProvider updates directly to staging IdP DB
class ServiceProviderUpdater
  def self.post_update(body = nil)
    resp = conn.post { |req| req.body = Zlib.gzip(body.to_json) if body.present? }

    status_code = resp.status
    return status_code if status_code == 200

    failure = StandardError.new "ServiceProviderUpdater failed with status: #{status_code}"
    handle_error(failure)
    status_code
  rescue StandardError => err
    handle_error(err)
    status_code
  end

  class << self
    def conn
      Faraday.new(url: idp_url, headers: headers)
    end

    def idp_url
      IdentityConfig.store.idp_sp_url
    end

    def headers
      {
        'X-LOGIN-DASHBOARD-TOKEN' => IdentityConfig.store.dashboard_api_token,
        'Content-Type' => 'gzip/json',
        'Content-Encoding' => 'gzip',
      }
    end

    def handle_error(error)
      ::NewRelic::Agent.notice_error(error)
    end
  end
end
