module SecurityEventHelper
  def friendly_name(security_event)
    doc_attrs = DevDocs.find_risc_event(security_event.event_type)

    doc_attrs&.friendly_name || security_event.event_type.split('/').last
  end

  def event_description(security_event)
    DevDocs.find_risc_event(security_event.event_type)&.description
  end
end
