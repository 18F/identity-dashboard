class Airtable # :nodoc:
  include ActiveModel::Model

  TOKEN_URI = 'https://airtable.com/oauth2/v1/token'
  REDIRECT_URI = 'http://localhost:3001/airtable/oauth/redirect'

  def initialize(user_uuid)
    @user_uuid = user_uuid
    @conn ||= Faraday.new(headers: self.tokenBearerAuthorizationHeader)
  end

  def getMatchingRecords(issuer)
    all_records_uri = 'https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk'

    @conn ||= Faraday.new(url: all_records_uri, headers: headers)

    resp = @conn.get(all_records_uri)
    response = JSON.parse(resp.body)

    response['records'].find do |r|
      r['fields']['Issuer String'] == issuer
    end
  end

  def getAdminIds(record)
    ids = []
    record['fields']['Partner Portal Admin'].each do |admin_id|
      ids.push(admin_id)
    end
    ids
  end

  def getAdminEmails(admin_ids)
    admin_emails = []
    admin_ids.each do |admin_id|
      user_record_uri = "https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk/#{admin_id}"

      user_resp = @conn.get(user_record_uri)
      user_response = JSON.parse(user_resp.body)

      admin_emails.push(user_response['fields']['Email'])
    end
    admin_emails
  end

  def requestToken(code)
    @conn.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    @conn.headers['Authorization'] = tokenBasicAuthorizationHeader

    request_data = { code: code,
                     redirect_uri: REDIRECT_URI,
                     grant_type: 'authorization_code',
                     code_verifier: Rails.cache.read("#{@user_uuid}.airtable_code_verifier") }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    resp = @conn.post(TOKEN_URI) { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    saveToken(response)
  end

  private

  def tokenBearerAuthorizationHeader
    # if Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration").present? &&
    #    Rails.cache.read("#{@user_uuid}.airtable_oauth_token_expiration") > Time.now
      { 'Authorization' => "Bearer #{Rails.cache.read("#{@user_uuid}.airtable_oauth_token")}" }
    # else 
    #   refreshToken
    # end
  end

  def tokenBasicAuthorizationHeader
    auth_string = Base64.urlsafe_encode64("#{IdentityConfig.store.airtable_oauth_client_id}:#{IdentityConfig.store.airtable_oauth_client_secret}")
    "Basic #{auth_string}"
  end

  def saveToken(response)
    Rails.cache.write("#{@user_uuid}.airtable_oauth_token", response['access_token'])
    Rails.cache.write("#{@user_uuid}.airtable_oauth_token_expiration", DateTime.now + response['expires_in'].seconds)
    Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token", response['refresh_token'])
    Rails.cache.write("#{@user_uuid}.airtable_oauth_refresh_token_expiration", DateTime.now + response['refresh_expires_in'].seconds)
  end

  def refreshToken
    @conn.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    @conn.headers['Authorization'] = tokenBasicAuthorizationHeader

    request_data = { refresh_token: 'oaa27QqGxYkFfQpVW.v1.refresh.eyJ1c2VySWQiOiJ1c3JCSnlUS0U0N3c2TGZYNCIsInJlZnJlc2hFeHBpcmF0aW9uVGltZSI6IjIwMjUtMTItMDhUMTY6MjA6NDYuMDAwWiIsIm9hdXRoQXBwbGljYXRpb25JZCI6Im9hcGV6clJ4OENqcEFWR2xSIiwic2VjcmV0IjoiMTY5Yzc2MTllOWMwY2RlNWViNmJjMTMxNDVkY2U4MDY0ZWEyOWM4MWQxYzk2MTVhZjRhYWMxMTRiN2I5OGVhYSJ9.f406a70ffc01dfc1949816857c08d26d2dc797cf46d2b3aed88cad41c316c1e4',
                     redirect_uri: REDIRECT_URI,
                     grant_type: 'refresh_token' }
    encoded_request_data = Faraday::Utils.build_query(request_data)

    refresh_resp = @conn.post(TOKEN_URI) { |req| req.body = encoded_request_data }
    refresh_response = JSON.parse(refresh_resp.body)

    saveToken(refresh_response)
  end

end
