# SalesforceController shows the status of the app's Salesforce connection
class SalesforceController < AuthenticatedController
  before_action -> { authorize SalesforceService }

  def index
    @token = SalesforceService.new.token
  rescue StandardError => err
    @connection_error = err.message
  end
end
