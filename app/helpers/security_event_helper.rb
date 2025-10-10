module SecurityEventHelper # :nodoc:
  def friendly_name(security_event)
    security_event.event_type.split('/').last
  end
end
