require 'rails_helper'

RSpec.describe RiscDestinationUpdater do
  subject(:updater) { RiscDestinationUpdater.new(service_provider) }

  let(:push_notification_url) { 'https://example.com/push' }
  let(:service_provider) do
    build(
      :service_provider,
      id: SecureRandom.random_number(1000),
      friendly_name: 'My Cool App',
      push_notification_url: push_notification_url,
    )
  end
  let(:service_provider_slug) { "issuer-#{service_provider.id}" }
  let(:connection_arn) { SecureRandom.hex }

  before do
    allow(Identity::Hostdata).to receive(:env).and_return('int')

    Aws.config[:eventbridge] = {
      stub_responses: {
        list_connections: { connections: existing_connections },
        create_connection: { connection_arn: connection_arn },
        update_connection: { connection_arn: connection_arn },
        list_api_destinations: { api_destinations: existing_api_desinations },
        list_rules: { rules: existing_rules },
        list_targets_by_rule: { targets: existing_targets },
      },
    }
  end
  let(:existing_connections) { [] }
  let(:existing_api_desinations) { [] }
  let(:existing_rules) { [] }
  let(:existing_targets) { [] }

  shared_examples_for 'removes_api_destination' do
    context 'when an API destination does not exist for the SP' do
      let(:existing_api_desinations) { [] }

      it 'no-ops' do
        expect(updater.eventbridge_client).to_not receive(:delete_api_destination)

        subject
      end
    end

    context 'when an API destination exists for the SP' do
      let(:existing_api_desinations) do
        [
          { connection_arn: connection_arn },
        ]
      end

      it 'removes the API destination' do
        expect(updater.eventbridge_client).to receive(:delete_api_destination).
          with(name: "int-risc-destination-#{service_provider_slug}").and_call_original

        subject
      end
    end
  end

  shared_examples_for 'removes_rules' do
    context 'when a rule does not exist for the SP' do
      let(:existing_rules) { [] }

      it 'no-ops' do
        expect(updater.eventbridge_client).to_not receive(:delete_rule)

        subject
      end
    end

    context 'when a rule exists for the SP' do
      let(:existing_rules) do
        [
          { name: "int-risc-rule-#{service_provider_slug}" },
        ]
      end

      it 'removes the API destination' do
        expect(updater.eventbridge_client).to receive(:delete_rule).
          with(
            name: "int-risc-rule-#{service_provider_slug}",
            event_bus_name: 'int-risc-notifications',
            force: true,
          ).and_call_original

        subject
      end
    end
  end

  describe '#update' do
    subject(:update) { updater.update }

    context 'when the SP has a push_notification_url' do
      let(:push_notification_url) { 'https://example.com/push' }

      context 'when an API destination does not exist for the SP' do
        it 'creates an API destination' do
          expect(updater.eventbridge_client).to receive(:create_api_destination).
            with(
              name: "int-risc-destination-#{service_provider_slug}",
              connection_arn: connection_arn,
              description: 'Destination for My Cool App',
              invocation_endpoint: push_notification_url,
              http_method: 'POST',
            ).and_call_original

          update
        end
      end

      context 'when an API destination exists for the SP' do
        let(:existing_api_desinations) do
          [
            { connection_arn: connection_arn },
          ]
        end

        it 'updates the existing API destination' do
          expect(updater.eventbridge_client).to receive(:update_api_destination).
            with(
              name: "int-risc-destination-#{service_provider_slug}",
              connection_arn: connection_arn,
              description: 'Destination for My Cool App',
              invocation_endpoint: push_notification_url,
              http_method: 'POST',
            ).and_call_original

          update
        end
      end
    end

    context 'when the SP has no push_notification_url' do
      let(:push_notification_url) { nil }

      it_behaves_like 'removes_api_destination'
      it_behaves_like 'removes_rules'
    end
  end

  describe '#remove' do
    subject(:remove) { updater.remove }

    it_behaves_like 'removes_api_destination'
    it_behaves_like 'removes_rules'
  end

  describe '#connection_name' do
    it 'includes the ENV and the issuer' do
      expect(updater.connection_name).to eq("int-risc-connection-#{service_provider_slug}")
    end
  end

  describe '#rule_name' do
    it 'includes the ENV and the issuer' do
      expect(updater.rule_name).to eq("int-risc-rule-#{service_provider_slug}")
    end
  end

  describe '#api_destination_name' do
    it 'includes the ENV and the issuer' do
      expect(updater.api_destination_name).to eq("int-risc-destination-#{service_provider_slug}")
    end
  end

  describe '#destination_iam_role_arn' do
    let(:aws_account_id) { SecureRandom.random_number(1e6) }

    before do
      allow(Identity::Hostdata::EC2).to receive_message_chain(:load, :account_id).
        and_return(aws_account_id)
    end

    it 'includes the AWS account id and the env' do
      expect(updater.destination_iam_role_arn).
        to eq("arn:aws:iam::#{aws_account_id}:role/int-risc-notification-destination")
    end
  end

  describe '#target_id' do
    it 'includes the ENV and the issuer' do
      expect(updater.target_id).to eq("int-risc-target-#{service_provider_slug}")
    end
  end

  describe '#event_bus_name' do
    it 'includes the ENV' do
      expect(updater.event_bus_name).to eq('int-risc-notifications')
    end
  end

  describe '#issuer_slug' do
    let(:service_provider) { build(:service_provider, id: SecureRandom.random_number(1000)) }

    it 'is the issuer DB id' do
      expect(updater.issuer_slug).to eq("issuer-#{service_provider.id}")
    end
  end
end
