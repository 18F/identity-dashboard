class ExtractsController < AuthenticatedController
  before_action -> { authorize Extract }

  before_action :log_request, only: %i[create]
  after_action -> { flash.discard }

  def index
    @extract ||= Extract.new
  end

  def create
    @extract ||= Extract.new

    ep = extracts_params
    @ticket = ep[:ticket] || ''
    @search_by = ep[:search_by] || ''
    @criteria_list = ep[:criteria_list] || ''

    list_criteria = @criteria_list.split(/,\s*|\s+/)
    @file = extracts_params[:criteria_file]
    @file_criteria = @file ? @file.read.split(/,\s*|\s+/) : []
    criteria = [].union list_criteria, @file_criteria

    configs = @search_by == 'teams' ?
      ServiceProvider.where(group_id: criteria) :
      ServiceProvider.where(issuer: criteria)

    @successes = configs
    @failures = find_failures criteria, configs

    if is_valid? && !configs.empty?
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
        @search_by == 'teams' ?
          config.group_id.to_s == criterion :
          config.issuer == criterion
      end
    end
    failures
  end

  def is_valid?
    ep = extracts_params
    @extract.errors.add(:ticket, 'number is required') if @ticket&.empty?
    if @search_by != 'teams' && @search_by != 'issuers'
      @extract.errors.add(:search_by, 'must be selected')
    end
    if !@criteria_file && @criteria_list&.empty?
      @extract.errors.add(:criteria_file, 'or Criteria list must contain criteria')
      @extract.errors.add(:criteria_list, 'or Criteria file must contain criteria')
    end

    @extract.errors.empty?
  end

  def save_to_file
    save_file = "/tmp/config_extract_#{extracts_params[:ticket]}"
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
