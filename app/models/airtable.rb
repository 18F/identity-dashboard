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

  def get_matching_records(issuers, offset = nil, matched_records = [])
    response = fetch_records(offset)
    matches = filter_records_by_issuers(response['records'], issuers)
    matched_records.concat(matches)

    return get_matching_records(issuers, response['offset'], matched_records) if response['offset']

    matched_records
  end

  def new_partner_admin_in_airtable?(email, record)
    record['fields']['Partner Portal Admin Email'].include?(email)
  end

  def request_token(code, redirect_uri)
    request_data = { code: code,
                     redirect_uri: redirect_uri,
                     grant_type: 'authorization_code',
                     code_verifier: Rails.cache.read("#{@user_uuid}.airtable_code_verifier") }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    resp = @conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    save_token(response)
  end

  def needs_refreshed_token?
    Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration").present? &&
      Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration") < DateTime.now
  end

  def refresh_token(redirect_uri)
    request_data = { refresh_token: Rails.cache.read("#{@user_uuid}.airtable_oauth_refresh_token"),
                     redirect_uri: redirect_uri,
                     grant_type: 'refresh_token' }
    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    refresh_resp = @conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    refresh_response = JSON.parse(refresh_resp.body)

    save_token(refresh_response)
  end

  def has_token?
    Rails.cache.read("#{@user_uuid}.airtable_oauth_token").present?
  end

  def generate_oauth_url(base_url)
    code_verifier = Rails.cache.fetch("#{@user_uuid}.airtable_code_verifier",
                                      expires_in: 10.minutes) do
      SecureRandom.alphanumeric(50)
    end
    airtable_state = Rails.cache.fetch("#{@user_uuid}.airtable_state",
                                       expires_in: 10.minutes) do
      SecureRandom.uuid
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

  def fetch_records(offset = nil)
    app_id = IdentityConfig.store.airtable_app_id
    table_id = IdentityConfig.store.airtable_table_id
    uri = "#{BASE_API_URI}/#{app_id}/#{table_id}?offset=#{offset}"

    @conn.headers = token_bearer_authorization_header
    resp = @conn.get(uri)
    JSON.parse(resp.body)
  end

  def filter_records_by_issuers(records, issuers)
    records.select do |record|
      issuer_string = record.dig('fields', 'Issuer String')
      issuer_string && issuers.any? { |issuer| issuer_string.include?(issuer) }
    end
  end

  def token_bearer_authorization_header
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Bearer #{Rails.cache.read("#{@user_uuid}.airtable_oauth_token")}" }
  end

  def token_basic_authorization_header
    client_id = IdentityConfig.store.airtable_oauth_client_id
    client_secret = IdentityConfig.store.airtable_oauth_client_secret
    auth_string = Base64.urlsafe_encode64("#{client_id}:#{client_secret}")
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{auth_string}" }
  end

  def save_token(response)
    Rails.cache.write("#{@user_uuid}.airtable_oauth_token", response['access_token'])
    Rails.cache.write("#{@user_uuid}.airtable_oauth_token_expiration",
                      DateTime.now + response['expires_in'].seconds)
    Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token", response['refresh_token'])
    Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token_expiration",
                      DateTime.now + response['refresh_expires_in'].seconds)
  end
end
