class AirtableController < ApplicationController
  def index
    session[:airtable_code_verifier] = SecureRandom.alphanumeric(43)
    session[:airtable_state] = SecureRandom.uuid
  end

  def issuer_lookup 
    return unless session[:airtable_state] == params[:state]

    all_records_uri = 'https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk'
    headers = { 'Authorization' => "Bearer #{session[:airtable_token]}" }
    @conn ||= Faraday.new(url: all_records_uri, headers: headers)

    resp = @conn.get(all_records_uri)
    response = JSON.parse(resp.body)

    issuer_to_find = 'GSA_LACR_DEV'
    record = response["records"].find do |r|
      r["fields"]["Issuer String"] == issuer_to_find
    end

    admin_emails = []
    record["fields"]["Partner Portal Admin"].each do |admin_id|

      user_record_uri = "https://api.airtable.com/v0/appCPBIq0sFQUZUSY/tbl8XAxD4G5uBEPMk/#{admin_id}"

      @conn ||= Faraday.new(url: user_record_uri, headers: headers)

      user_resp = @conn.get(user_record_uri)
      user_response = JSON.parse(user_resp.body)

      admin_emails.push(user_response["fields"]["Email"])

    end
    render json: admin_emails
  end

  def code
    return unless session[:airtable_state] == params[:state]

    token_uri = 'https://airtable.com/oauth2/v1/token'
    auth_bearer = Base64.urlsafe_encode64("#{IdentityConfig.store.airtable_oauth_client_id}:#{IdentityConfig.store.airtable_oauth_client_secret}")

    headers = { 'Content-Type' => 'application/x-www-form-urlencoded',
                'Authorization' => "Basic #{auth_bearer}" }

    redirect_uri = "#{request.protocol}#{request.host_with_port}/airtable/oauth/redirect"
    @conn ||= Faraday.new(url: token_uri, headers: headers)

    request_data = { code: params[:code],
                     redirect_uri: redirect_uri,
                     grant_type: 'authorization_code',
                     code_verifier: session[:airtable_code_verifier] }

    encoded_request_data = Faraday::Utils.build_query(request_data)

    resp = @conn.post(token_uri) { |req| req.body = encoded_request_data }
    response = JSON.parse(resp.body)

    token = response['access_token']

    session[:airtable_token] = token
    
    redirect_to airtable_path
  end

  def clear_token
    session.delete(:airtable_token)
    redirect_to airtable_path
  end

end
