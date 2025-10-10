class Airtable # :nodoc:
  include ActiveModel::Model

  TOKEN_URI = 'https://airtable.com/oauth2/v1/token'
  REDIRECT_URI = 'http://localhost:3001/airtable/oauth/redirect'

  def initialize(user_uuid)
    @user_uuid = user_uuid
    @conn ||= Faraday.new
  end

  def get_matching_records(issuers)
    all_records_uri = 'https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk?maxRecords=1000'

    @conn.headers = token_bearer_authorization_header
    @conn ||= Faraday.new(url: all_records_uri)

    resp = @conn.get(all_records_uri)
    response = JSON.parse(resp.body)
    matched_records = []
    response['records'].each do |r|
      matched_records.push(r) if issuers.any? do |issuer|
        r['fields']['Issuer String'].include?(issuer)
      end
    end

    matched_records
  end

  def get_admin_emails_for_record(record)
    admin_ids = []
    record['fields']['Partner Portal Admin'].each do |admin_id|
      admin_ids.push(admin_id)
    end

    admin_emails = []
    admin_ids.each do |admin_id|
      user_record_uri = "https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk/#{admin_id}"

      @conn.headers = token_bearer_authorization_header
      user_resp = @conn.get(user_record_uri)
      user_response = JSON.parse(user_resp.body)

      admin_emails.push(user_response['fields']['Email'].downcase)
    end
    admin_emails
  end

  def isNewPartnerAdminInAirtable?(email, record)
    get_admin_emails_for_record(record).include?(email.downcase)
  end

  def request_token(code)
    request_data = { code: code,
                     redirect_uri: REDIRECT_URI,
                     grant_type: 'authorization_code',
                     code_verifier: Rails.cache.read("#{@user_uuid}.airtable_code_verifier") }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    resp = @conn.post(TOKEN_URI) { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    save_token(response)
  end

  def needs_refreshed_token?
    Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration").present? &&
      Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration") < DateTime.now
  end

  def refresh_token
    request_data = { refresh_token: Rails.cache.read("#{@user_uuid}.airtable_oauth_refresh_token"),
                     redirect_uri: REDIRECT_URI,
                     grant_type: 'refresh_token' }
    encoded_request_data = Faraday::Utils.build_query(request_data)

    @conn.headers = token_basic_authorization_header
    refresh_resp = @conn.post(TOKEN_URI) { |req| req.body = encoded_request_data }
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
    "https://airtable.com/oauth2/v1/authorize?response_type=code&client_id=#{client_id}&redirect_uri=#{redirect_uri}&state=#{airtable_state}&code_challenge_method=S256&code_challenge=#{code_challenge}"
  end

  private

  def headers
    refresh_token if needs_refreshed_token?
    token_basic_authorization_header
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
