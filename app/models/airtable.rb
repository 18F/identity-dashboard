# The Airtable model handles the OAuth connection with Airtable
# as well as sending requests to the Airtable API and managing
# the returned data
class Airtable < ApplicationRecord

  belongs_to :user

  BASE_TOKEN_URI = 'https://airtable.com/oauth2/v1'
  BASE_API_URI = 'https://api.airtable.com/v0'

  def initialize(user)
    super()

    self.user = user
    prepare_api
  end

  def get_matching_records(issuers, offset = nil, matched_records = nil)
    app_id = IdentityConfig.store.airtable_app_id
    table_id = IdentityConfig.store.airtable_table_id
    all_records_uri = "#{BASE_API_URI}/#{app_id}/#{table_id}?offset=#{offset}"

    conn = Faraday.new(url: all_records_uri)
    conn.headers = token_bearer_authorization_header

    resp = conn.get(all_records_uri)
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
    request_data = { code: code,
                     redirect_uri: redirect_uri,
                     grant_type: 'authorization_code',
                     code_verifier: self.code_verifier }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    conn = Faraday.new
    conn.headers = token_basic_authorization_header
    resp = conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    save_token(response)
  end

  def needs_refreshed_token?
    self.token_expiration.present? &&
      self.token_expiration < DateTime.now
  end

  def refresh_oauth_token(redirect_uri)
    request_data = { refresh_token: self.refresh_token,
                     redirect_uri: redirect_uri,
                     grant_type: 'refresh_token' }
    encoded_request_data = Faraday::Utils.build_query(request_data)

    conn = Faraday.new
    conn.headers = token_basic_authorization_header
    refresh_resp = conn.post("#{BASE_TOKEN_URI}/token") { |req| req.body = encoded_request_data }
    refresh_response = JSON.parse(refresh_resp.body)

    save_token(refresh_response)
  end

  def has_token?
    self.token.present?
  end

  def generate_oauth_url(base_url)
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(self.code_verifier)).delete('=')
    redirect_uri = "#{base_url}/airtable/oauth/redirect&scope=data.records:read"

    client_id = IdentityConfig.store.airtable_oauth_client_id

    # rubocop:disable Layout/LineLength
    "#{BASE_TOKEN_URI}/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}&state=#{self.state}&code_challenge_method=S256&code_challenge=#{code_challenge}"
    # rubocop:enable Layout/LineLength
  end

  def build_redirect_uri(request)
    base_url = "#{request.protocol}#{request.host_with_port}"
    "#{base_url}/airtable/oauth/redirect"
  end

  def generate_state
    SecureRandom.uuid
  end

  def generate_code_verifier
    SecureRandom.hex(50)
  end

  def prepare_api
    self.state = generate_state
    self.code_verifier = generate_code_verifier
    save!
  end

  private

  def token_bearer_authorization_header
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Bearer #{self.token}" }
  end

  def token_basic_authorization_header
    client_id = IdentityConfig.store.airtable_oauth_client_id
    client_secret = IdentityConfig.store.airtable_oauth_client_secret
    auth_string = Base64.urlsafe_encode64("#{client_id}:#{client_secret}")
    { 'Content-Type' => 'application/x-www-form-urlencoded',
      'Authorization' => "Basic #{auth_string}" }
  end

  def save_token(response)
    self.token = response['access_token']
    self.token_expiration = DateTime.now + response['expires_in'].seconds
    self.refresh_token = response['refresh_token']
    self.refresh_token_expiration = DateTime.now + response['refresh_expires_in'].seconds

    save
    # Rails.cache.write("#{@user_uuid}.airtable_oauth_token", response['access_token'])
    # Rails.cache.write("#{@user_uuid}.airtable_oauth_token_expiration",
    #   DateTime.now + response['expires_in'].seconds)
    # Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token", response['refresh_token'])
    # Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token_expiration",
    #   DateTime.now + response['refresh_expires_in'].seconds)
  end
end
