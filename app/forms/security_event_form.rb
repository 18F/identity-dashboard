# Parses RISC Security Event Token (SETs)
class SecurityEventForm
  attr_reader :body

  include ActiveModel::Model

  validates_presence_of :payload
  validates_presence_of :event_type
  validates_presence_of :user

  # @param [String] body
  def initialize(body:)
    @body = body
  end

  # @return [Array(Boolean, ActiveModel::Errors)]
  def submit
    if valid?
      create_security_event!
      [true, nil]
    else
      [false, errors]
    end
  end

  def create_security_event!
    SecurityEvent.create!(
      user:,
      uuid: payload['jti'],
      event_type:,
      issued_at: payload['iat'] ? Time.zone.at(payload['iat']) : nil,
      raw_event: payload.to_json,
    )
  end

  # rubocop:disable Metrics/MethodLength
  def payload
    @payload ||= begin
      payload = nil

      IdpPublicKeys.all.each do |public_key|
        payload, _headers = JWT.decode(
          body, public_key, true, algorithm: 'RS256', leeway: Float::INFINITY
        )
        break if payload
      rescue JWT::DecodeError
        next
      end

      return payload if payload

      errors.add(:jwt, 'could not verify JWT with any known keys')
      {}
    end
  end
  # rubocop:enable Metrics/MethodLength

  def event_type
    (payload['events'] || {}).keys.first
  end

  def subject
    payload.dig('events', event_type, 'subject') || {}
  end

  def user
    subject_type = subject['subject_type']

    case subject['subject_type']
    when 'email'
      User.find_by(email: subject['email'])
    when 'iss-sub'
      User.find_by(uuid: subject['sub'])
    else
      errors.add(:subject_type, "unknown subject_type #{subject_type}")
    end
  end
end
