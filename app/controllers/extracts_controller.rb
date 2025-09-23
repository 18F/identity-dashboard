class ExtractsController < AuthenticatedController
  before_action -> { authorize Extract }

  before_action :log_request, only: %i[create]
  after_action -> { flash.discard }

  def index
    @extract ||= Extract.new({})
  end

  def create
    @extract = Extract.new(extracts_params)

    criteria = [].union @extract.list_criteria, @extract.file_criteria

    configs = @extract.search_by == 'teams' ?
      ServiceProvider.where(group_id: criteria) :
      ServiceProvider.where(issuer: criteria)

    @successes = configs
    @failures = find_failures criteria, configs

    if @extract.valid? && !configs.empty?
      if @failures.length > 0
        flash[:warning] = 'Some criteria were invalid. Please check the results.'
      end
      save_to_file
      return render 'results'
    elsif @extract.errors.empty? && configs.empty?
      flash[:error] = 'No ServiceProvider rows were returned'
    end

    render 'index'
  end

  private

  def extracts_params
    params.require(:extract).permit(
      :ticket,
      :search_by,
      :criteria_file,
      :criteria_list,
    )
  end

  def find_failures(criteria, configs)
    failures = []
    criteria.each do |criterion|
      failures.push criterion unless configs.find do |config|
        @extract.search_by == 'teams' ?
          config.group_id.to_s == criterion :
          config.issuer == criterion
      end
    end
    failures
  end

  def save_to_file
    save_file = "/tmp/config_extract_#{@extract.ticket}"
    begin
      File.open(save_file, 'w') do |f|
        f.print @successes.to_json
      end
      flash[:success] = "Extracted configs written to #{save_file}"
    rescue => err
      flash[:error] = "There was a problem writing to #{save_file}: #{err}"
    end
  end

  def log_request
    log.extraction_request(action_name, extracts_params)
  end
end
