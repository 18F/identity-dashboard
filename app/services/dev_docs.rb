# Helps load metadata from developer documentation site
class DevDocs
  RiscEvent = Struct.new(:event_type, :friendly_name, :description, keyword_init: true)

  # @return [Hash<String,RiscEvent>]
  def self.risc_events
    Rails.cache.fetch('data/risc.json', expires_in: 12.hours) do
      new.load_risc_events.map { |risc| [ risc.event_type, risc ] }.to_h
    end
  end

  # @return [RiscEvent,nil]
  def self.find_risc_event(event_type)
    risc_events[event_type]
  end

  attr_reader :dev_docs_url

  def initialize(dev_docs_url: Figaro.env.dev_docs_url)
    @dev_docs_url = dev_docs_url
  end

  # @return [Array<RiscEvent>]
  def load_risc_events
    data_url = URI.join(dev_docs_url, 'data/risc.json')
    Rails.logger.info("requesting #{data_url}")

    response = Faraday.get(data_url)
    json = JSON.parse(response.body, symbolize_names: true)

    Array(json[:supported_events]).map do |attrs|
      RiscEvent.new(**attrs.slice(*RiscEvent.members))
    end.select(&:event_type)
  rescue Faraday::ConnectionFailed, JSON::ParserError => e
    Rails.logger.warn(e)
    []
  end
end
