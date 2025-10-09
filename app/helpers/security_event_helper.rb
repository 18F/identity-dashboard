# Helper for SecurityEvent view
module SecurityEventHelper
  def friendly_name(security_event)
    security_event.event_type.split('/').last
  end
end
