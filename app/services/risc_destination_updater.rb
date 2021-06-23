require 'aws-sdk-eventbridge'

class RiscDestinationUpdater
  attr_reader :service_provider

  def initialize(service_provider)
    @service_provider = service_provider
  end

  def update
    if service_provider.push_notification_url.present?
      put_rule
      connection_arn = create_or_update_connnection
      api_destination_arn = create_or_update_api_destination(connection_arn)
      put_targets(api_destination_arn)
    else
      remove
    end
  end

  def remove
    remove_rule if rule_exists?
    eventbridge_client.delete_api_destination(name: api_destination_name) if api_destination_exists?
    eventbridge_client.delete_connection(name: connection_name) if connection_exists?
  end

  def issuer_slug
    @issuer_slug ||= service_provider.issuer.gsub(/[^.\-_A-Za-z0-9]/, '_')
  end

  def connection_name
    "#{Identity::Hostdata.env}-risc-connection-#{issuer_slug}"
  end

  def rule_name
    "#{Identity::Hostdata.env}-risc-rule-#{issuer_slug}"
  end

  def api_destination_name
    "#{Identity::Hostdata.env}-risc-destination-#{issuer_slug}"
  end

  def target_id
    "#{Identity::Hostdata.env}-risc-target-#{issuer_slug}"
  end

  def event_bus_name
    # Matches value managed by Terraform
    "#{Identity::Hostdata.env}-risc-notifications"
  end

  def destination_iam_role_arn
    # Matches value managed by Terraform
    "arn:aws:iam::#{aws_account_id}:role/#{Identity::Hostdata.env}-risc-notification-destination"
  end

  def rule_exists?
    eventbridge_client.list_rules(
      name_prefix: rule_name,
      event_bus_name: event_bus_name,
      limit: 1,
    ).rules.first.present?
  end

  def put_rule
    eventbridge_client.put_rule(
      name: rule_name,
      event_pattern: {
        account: [aws_account_id],
        source: [service_provider.issuer],
      }.to_json,
      state: 'ENABLED',
      description: "Rule for for #{service_provider.friendly_name}",
      event_bus_name: event_bus_name,
    )
  end

  def put_targets(api_destination_arn)
    eventbridge_client.put_targets(
      rule: rule_name,
      event_bus_name: event_bus_name,
      targets: [
        id: target_id,
        role_arn: destination_iam_role_arn,
        arn: api_destination_arn,
        input_path: '$.detail',
        http_parameters: {
          header_parameters: {
            'Content-Type' => 'application/secevent+jwt',
          },
        },
      ],
    )
  end

  def remove_rule
    target_ids = eventbridge_client.list_targets_by_rule(
      rule: rule_name,
      event_bus_name: event_bus_name,
    ).targets.map(&:id)

    # Must remove targets before we can delete a rule
    eventbridge_client.remove_targets(
      rule: rule_name,
      event_bus_name: event_bus_name,
      ids: target_ids,
    )

    eventbridge_client.delete_rule(name: rule_name, force: true)
  end

  def connection_exists?
    eventbridge_client.list_connections(
      name_prefix: connection_name,
      limit: 1,
    ).connections.first.present?
  end

  # @return [String] connection ARN
  def create_or_update_connnection
    connection_attrs = {
      name: connection_name,
      authorization_type: 'API_KEY',
      auth_parameters: {
        api_key_auth_parameters: {
          api_key_name: 'X-Login-Gov-Source',
          api_key_value: 'EventBridge',
        },
      },
    }

    response = if connection_exists?
      eventbridge_client.update_connection(connection_attrs)
    else
      eventbridge_client.create_connection(connection_attrs)
    end

    response.connection_arn
  end

  def api_destination_exists?
    eventbridge_client.list_api_destinations(
      name_prefix: api_destination_name,
      limit: 1,
    ).api_destinations.first.present?
  end

  # @return [String] api destination ARN
  def create_or_update_api_destination(connection_arn)
    api_destination_attrs = {
      name: api_destination_name,
      connection_arn: connection_arn,
      description: "Destination for #{service_provider.friendly_name}",
      invocation_endpoint: service_provider.push_notification_url,
      http_method: 'POST',
    }

    response = if api_destination_exists?
      eventbridge_client.update_api_destination(api_destination_attrs)
    else
      eventbridge_client.create_api_destination(api_destination_attrs)
    end

    response.api_destination_arn
  end

  def aws_account_id
    Identity::Hostdata::EC2.load.account_id
  rescue Net::OpenTimeout,
         Errno::EHOSTDOWN,
         Errno::EHOSTUNREACH,
         WebMock::NetConnectNotAllowedError => e
    raise e if Identity::Hostdata.in_datacenter?

    '123456'
  end

  def eventbridge_client
    @eventbridge_client ||= Aws::EventBridge::Client.new(region: IdentityConfig.store.aws_region)
  end
end
