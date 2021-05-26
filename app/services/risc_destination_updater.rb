require 'aws-sdk-eventbridge'

class RiscDestinationUpdater
  attr_reader :service_provider

  def initialize(service_provider)
    @service_provider = service_provider
  end

  def update
    if service_provider.push_notification_url.present?
      if api_destination_exists?
        eventbridge_client.update_api_destination(api_destination_attributes)
      else
        eventbridge_client.create_api_destination(api_destination_attributes)
      end
    else
      remove
    end
  end

  def remove
    if api_destination_exists?
      eventbridge_client.delete_api_destination(name: api_destination_name)
    end
  end

  def api_destination_exists?
    eventbridge_client.list_api_destinations(
      name_prefix: api_destination_name,
      limit: 1
    ).api_destinations.first.present?
  end

  def api_destination_name
    "#{Identity::Hostdata.env}-#{service_provider.issuer}"
  end

  def api_destination_attributes
    {
      name: api_destination_name,
      connection_arn: connection_arn,
      description: "Destination for #{service_provider.friendly_name}",
      invocation_endpoint: service_provider.push_notification_url,
      http_method: 'POST',
    }
  end

  def connection_arn
    eventbridge_client.list_connections(
      name_prefix: '???', # TODO: fixme
      limit: 1,
    ).connections.first.connection_arn
  end

  def eventbridge_client
    @eventbridge_client ||= Aws::EventBridge::Client.new
  end
end
