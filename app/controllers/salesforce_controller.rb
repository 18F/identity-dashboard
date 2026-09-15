# SalesforceController shows the status of the app's Salesforce connection
# and lets an admin run an ad-hoc lookup by team.
class SalesforceController < AuthenticatedController
  before_action -> { authorize Salesforce }

  def index
    @token = salesforce_api.token
    @teams = Team.order(:name)
    load_query_results if params[:team_id].present?
  rescue ActiveRecord::RecordNotFound
    @connection_error = "Team #{params[:team_id]} not found."
  rescue StandardError => err
    @connection_error = err.message
  end

  private

  def load_query_results
    @team = Team.find(params[:team_id])
    team_uuids = @team.uuids_string.split(',')
    @records = salesforce_api.application_contacts_for_team_uuids(team_uuids)
    @soql = salesforce_api.last_soql
  end

  def salesforce_api
    @salesforce_api ||= Salesforce.new
  end
end
