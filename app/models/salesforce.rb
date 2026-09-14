# The Salesforce model handles the client credentials connection to
# Salesforce and sending requests to the Salesforce REST API.
class Salesforce
  include ActiveModel::Model

  TOKEN_CACHE_KEY = 'salesforce_oauth_token'.freeze
  # Salesforce does not report an expiration for the client credentials
  # grant, so this is a conservative guess rather than a real TTL.
  TOKEN_TTL = 15.minutes

  API_VERSION = 'v67.0'.freeze

  APPLICATION_CONTACT_OBJECT = 'LDGCRM_Application_Contact__c'.freeze

  APPLICATION_CONTACT_FIELDS = %w[
    Id
    Name
    LDGCRM_Email__c
    LDGCRM_P3_Team_UUID__c
    LGDCRM_P3_Partner_Portal_Admin__c
    LDGCRM_contact__r.Name
    LDGCRM_Application__r.Name
  ].freeze

  attr_reader :last_soql

  def initialize
    @conn = Faraday.new(url: IdentityConfig.store.salesforce_instance_url)
  end

  def token
    Rails.cache.fetch(TOKEN_CACHE_KEY, expires_in: TOKEN_TTL) { fetch_token }
  end

  # Application Contact records whose team UUID is any of the given values.
  # Returns [] immediately, without a request, when there are none to look up.
  def application_contacts_for_team_uuids(team_uuids)
    return [] if team_uuids.blank?

    Array(query(soql_for_team_uuids(team_uuids))['records'])
  end

  private

  def soql_for_team_uuids(team_uuids)
    quoted = team_uuids.map { |uuid| "'#{escape_literal(uuid)}'" }.join(', ')
    @last_soql = "SELECT #{APPLICATION_CONTACT_FIELDS.join(', ')} " \
      "FROM #{APPLICATION_CONTACT_OBJECT} WHERE LDGCRM_P3_Team_UUID__c IN (#{quoted})"
  end

  # A team UUID never contains a quote or backslash in practice, but this is
  # user-reachable data going into a query language, so it gets escaped like
  # any other SOQL string literal.
  def escape_literal(value)
    value.to_s.gsub(/([\\'])/) { "\\#{Regexp.last_match(1)}" }
  end

  def query(soql)
    resp = @conn.get("/services/data/#{API_VERSION}/query") do |req|
      req.headers['Authorization'] = "Bearer #{token}"
      req.params['q'] = soql
    end
    parsed = JSON.parse(resp.body)

    # Query errors come back as a JSON array of objects, not a hash.
    raise "Salesforce query failed (HTTP #{resp.status}): #{query_error_detail(parsed)}" unless
      resp.status == 200

    parsed
  end

  def query_error_detail(parsed)
    first = parsed.is_a?(Array) ? parsed.first : parsed
    first.is_a?(Hash) ? (first['message'] || first['errorCode']) : parsed.to_s
  end

  def fetch_token
    resp = post_token_request
    response = JSON.parse(resp.body)
    return response['access_token'] if resp.status == 200 && response['access_token']

    raise "Salesforce rejected the credentials: #{token_error_detail(response)}"
  end

  def post_token_request
    @conn.post('/services/oauth2/token') do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = URI.encode_www_form(
        grant_type: 'client_credentials',
        client_id: IdentityConfig.store.salesforce_consumer_key,
        client_secret: IdentityConfig.store.salesforce_consumer_secret,
      )
    end
  end

  def token_error_detail(response)
    [response['error'], response['error_description']].compact.join(': ')
  end
end
