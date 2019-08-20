# These endpoints are only for manually testing push notifications from the IDP
class PushNotificationController < ApplicationController
  protect_from_forgery except: :push_notification
  before_action :development_only

  EVENT_TYPE_URI = 'https://schemas.openid.net/secevent/risc/event-type/account-purged'.freeze

  def push_notification
    authorization = request.headers['authorization']
    token = authorization.match(/WebPush (.*)/)[1]

    @decoded_token = JSON::JWT.decode(token, public_jwk)
    puts "\nReceived JWT token:"
    pp @decoded_token

    user = User.where(uuid: @decoded_token['events'][EVENT_TYPE_URI]['subject']['sub']).first
    puts "\nFound deleted user:"
    pp user
  end

  private

  def public_keys
    return @public_keys if @public_keys

    certs_json = HTTParty.get('http://localhost:3000/api/openid_connect/certs').body
    @public_keys = JSON.parse(certs_json).deep_symbolize_keys
  end

  def public_jwk
    JSON::JWK.new(public_keys[:keys][0])
  end

  def development_only
    not_found unless Rails.env.development?
  end
end
