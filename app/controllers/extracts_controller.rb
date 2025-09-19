class ExtractsController < AuthenticatedController
  before_action -> { authorize Extract }

  before_action :log_request, only: %i[create]

  def index
    @extract ||= Extract.new
  end

  def create
    extracts_params.to_h => {
      ticket:,
      team_search:,
      extract_list:,
    }
    list_criteria = extract_list.split(/,\s*|\s+/) unless extract_list.strip.empty?
    file_criteria = []
    criteria = [].union list_criteria, file_criteria

    configs = team_search == 'true' ?
      ServiceProvider.where(group_id: criteria) :
      ServiceProvider.where(issuer: criteria)

    if configs.empty?
      flash[:error] = 'No ServiceProvider rows were returned.'
    elsif configs.length != criteria.length
      flash[:notice] = "Some issuers were invalid. Please check the results."
    end

    @team_search = team_search
    @successes = configs
    @failures = find_failures criteria, configs

    render 'results'
  end

  private

  def find_failures(criteria, configs)
    failures = [] 
    criteria.each do |criterion|
      failures.push criterion unless configs.find do |config|
        @team_search == 'true' ?
          config.group_id == criterion :
          config.issuer == criterion
      end
    end
    failures
  end

  def extracts_params
    params.require(:extract).permit(
      :ticket,
      :team_search,
      :criteria_file,
      :extract_list,
    )
  end

  def log_request
    log.extraction_request(action_name, extracts_params)
  end
end
