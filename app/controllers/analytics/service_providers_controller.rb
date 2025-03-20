require 'aws-sdk-core'
require 'aws-sdk-quicksight'

class Analytics::ServiceProvidersController < ApplicationController
    before_action -> { authorize User, policy_class: AnalyticsPolicy }

    AWS_ACCOUNT_ID = Aws::STS::Client.new.get_caller_identity.account
    # USER_ARN = 'arn:aws:quicksight:us-west-2:487317109730:user/default/admin@gsa.gov'
    USER_ARN = 'arn:aws:quicksight:us-west-2:487317109730:user/default/DWAdmin/colter.nattrass'
    DASHBOARD_ID = '0edede6f-3267-4fd1-8196-5529c2f287a6'
    EMAIL = 'admin@gsa.gov'
    REGION = 'us-west-2'
    ROLE_ARN = 'arn:aws:iam::487317109730:role/'
    ROLE_SESSION_NAME = 'YourSessionName'


    def show
       @issuer = service_provider.issuer
       @friendly_name = service_provider.friendly_name.capitalize
       @quicksight_user = register_quicksight_user(quicksight_client, AWS_ACCOUNT_ID, EMAIL, REGION)
       @dashboard_embed_url = fetch_quicksight_embed_url(quicksight_client, AWS_ACCOUNT_ID, USER_ARN, DASHBOARD_ID, REGION) # rubocop:disable Layout/LineLength
        @issuer = service_provider.issuer
#         @quicksight_user = register_quicksight_user(quicksight_client, AWS_ACCOUNT_ID, EMAIL,
# REGION)
        @dashboard_embed_url = fetch_quicksight_embed_url_for_registered_user(quicksight_client, AWS_ACCOUNT_ID, USER_ARN, DASHBOARD_ID, REGION) # rubocop:disable Layout/LineLength
        # @dashboard_embed_url = fetch_quicksight_embed_url_for_anonymous_user(quicksight_client, AWS_ACCOUNT_ID, DASHBOARD_ID, REGION)
        respond_to do |format|
            format.html # renders show.html.erb
            format.json { render json: { embed_url: @dashboard_embed_url } }
        end
    end

    private

    def service_provider
        @service_provider ||= ServiceProvider.includes(:agency,
logo_file_attachment: :blob).find(id)
    end

    def id
        @id ||= params[:id]
    end

    def sts_client
        @sts_client ||= Aws::STS::Client.new(region: REGION)
    end

    def assume_role(client, role_arn, role_session_name)
        client.assume_role({
            role_arn:,
            role_session_name:,
        })
    end

    def quicksight_client
        @quicksight_client ||= Aws::QuickSight::Client.new(region: REGION)
    end

    # def register_quicksight_user(client, aws_account_id, email, region)
    #     Rails.logger.debug("Registering QuickSight user with aws_account_id: #{aws_account_id}, email: #{email}, region: #{region}")
    #     response = client.register_user({
    #         aws_account_id: aws_account_id,
    #         namespace: 'default',
    #         identity_type: 'QUICKSIGHT',
    #         user_role: 'READER',
    #         email: email,
    #         user_name: email,
    #     })
    #     response.user
    # end

    def fetch_quicksight_embed_url_for_registered_user(client, aws_account_id, user_arn,
                                                       dashboard_id, region)
        Rails.logger.debug("Fetching QuickSight embed URL with aws_account_id: #{aws_account_id}, user_arn: #{user_arn}, dashboard_id: #{dashboard_id}, region: #{region}")
        result = client.generate_embed_url_for_registered_user({
            aws_account_id: aws_account_id,
            session_lifetime_in_minutes: 600,
            user_arn: user_arn,
            experience_configuration: { # required
                dashboard: {
                initial_dashboard_id: dashboard_id, # required
                    feature_configurations: {
                        state_persistence: {
                            enabled: false, # required
                        },
                        bookmarks: {
                            enabled: false, # required
                        },
                    },
                },
            },
            allowed_domains: ['http://localhost'],
        })
        # Rails.logger.debug("Response: #{result.embed_url}")
        result.embed_url

    end

    # def fetch_quicksight_embed_url_for_anonymous_user(client, aws_account_id, dashboard_id)
    #     Rails.logger.debug("Fetching QuickSight embed URL for anonymous user with aws_account_id: #{aws_account_id}, dashboard_id: #{dashboard_id}")
    #     response = client.generate_embed_url_for_anonymous_user({
    #         aws_account_id: aws_account_id,
    #         session_lifetime_in_minutes: 600,
    #         namespace: 'default',
    #         experience_configuration: {
    #             dashboard: {
    #                 initial_dashboard_id: dashboard_id,
    #                 feature_configurations: {
    #                     state_persistence: {
    #                         enabled: false,
    #                     },
    #                     bookmarks: {
    #                         enabled: false,
    #                     },
    #                 },
    #             },
    #         },
    #         allowed_domains: ['http:localhost'],
    #     })
    #
    #     response.embed_url
    # end


end