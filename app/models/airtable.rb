# The Airtable model handles the OAuth connection with Airtable
# as well as sending requests to the Airtable API and managing
# the returned data
class Airtable
  include ActiveModel::Model

  BASE_TOKEN_URI = 'https://airtable.com/oauth2/v1'
  BASE_API_URI = 'https://api.airtable.com/v0'

  def initialize(user_uuid)
    @user_uuid = user_uuid
    @conn ||= Faraday.new
  end

  def get_matching_records(issuers, offset = nil, matched_records = nil)
    app_id = IdentityConfig.store.airtable_app_id
    table_id = IdentityConfig.store.airtable_table_id
    all_records_uri = "#{BASE_API_URI}/#{app_id}/#{table_id}?offset=#{offset}"

    @conn.headers = token_bearer_authorization_header
    @conn ||= Faraday.new(url: all_records_uri)

    resp = @conn.get(all_records_uri)
    response = JSON.parse(resp.body)
    matched_records ||= []
    issuers.each do |issuer|
      response['records'].select do |r|
        matched_records.push(r) if r['fields']['Issuer String'].include?(issuer)
      end
    end

    get_matching_records(issuers, response['offset'], matched_records) if response['offset']

    matched_records
  end

  def new_partner_admin_in_airtable?(email, record)
    record['fields']['Partner Portal Admin Email'].include?(email)
  end

  def request_token(code, redirect_uri)
    code_verifier = REDIS_POOL.with do |redis|
      redis.get("#{@user_uuid}.airtable_code_verifier")
    end
    request_data = { code: code,
                     redirect_uri: redirect_uri,
                     grant_type: 'authorization_code',
                     code_verifier: code_verifier }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    resp = @conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    save_token(response)
  end

  def needs_refreshed_token?
    token_ttl, refresh_token_ttl = REDIS_POOL.with do |redis|
      [redis.TTL("#{@user_uuid}.airtable_oauth_token"),
        redis.TTL("#{@user_uuid}.airtable_oauth_refresh_token")]
    end

    token_ttl < 0 && refresh_token_ttl > 0
  end

  def refresh_token(redirect_uri)
    refresh_t = REDIS_POOL.with do |redis|
      redis.get("#{@user_uuid}.airtable_oauth_refresh_token")
    end

    request_data = { refresh_token: refresh_t,
                     redirect_uri: redirect_uri,
                     grant_type: 'refresh_token' }
    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    refresh_resp = @conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    refresh_response = JSON.parse(refresh_resp.body)

    save_token(refresh_response)
  end

  def has_token?
    token_exists = REDIS_POOL.with do |redis|
      redis.exists("#{@user_uuid}.airtable_oauth_token")
    end

    token_exists
  end

  def generate_oauth_url(base_url)
    code_verifier, airtable_state = REDIS_POOL.with do |redis|
      redis.setex("#{@user_uuid}.airtable_code_verifier", 10.minutes, SecureRandom.alphanumeric(50))
      redis.setex("#{@user_uuid}.airtable_state", 10.minutes, SecureRandom.uuid)

      [redis.get("#{@user_uuid}.airtable_code_verifier"), redis.get("#{@user_uuid}.airtable_state")]
    end
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).delete('=')
    redirect_uri = "#{base_url}/airtable/oauth/redirect&scope=data.records:read"

    client_id = IdentityConfig.store.airtable_oauth_client_id

    # rubocop:disable Layout/LineLength
    "#{BASE_TOKEN_URI}/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}&state=#{airtable_state}&code_challenge_method=S256&code_challenge=#{code_challenge}"
    # rubocop:enable Layout/LineLength
  end

  def build_redirect_uri(request)
    base_url = "#{request.protocol}#{request.host_with_port}"
    "#{base_url}/airtable/oauth/redirect"
  end

  private

  def token_bearer_authorization_header
    auth_string = REDIS_POOL.with do |redis|
      redis.exists("#{@user_uuid}.airtable_oauth_token")
    end
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Bearer #{auth_string}" }
  end

  def token_basic_authorization_header
    client_id = IdentityConfig.store.airtable_oauth_client_id
    client_secret = IdentityConfig.store.airtable_oauth_client_secret
    auth_string = Base64.urlsafe_encode64("#{client_id}:#{client_secret}")
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{auth_string}" }
  end

  def save_token(response)
    return unless response['access_token'].present?
    REDIS_POOL.with do |redis|
      redis.setex("#{@user_uuid}.airtable_oauth_token",
                   response['expires_in'].seconds,
                   response['access_token'])

      redis.setex("#{@user_uuid}.airtable_oauth_refresh_token",
                   response['refresh_expires_in'].seconds,
                   response['refresh_token'])
    end
  end
end
