class ExtractsController < AuthenticatedController # :nodoc:
  before_action -> { authorize Extract }

  before_action :log_request, only: %i[create]
  after_action -> { flash.discard }

  def index
    @extract ||= Extract.new
  end

  def create
    @extract = Extract.new(
      ticket: extracts_params[:ticket],
      search_by: extracts_params[:search_by],
      criteria_list: extracts_params[:criteria_list],
      criteria_file: extracts_params[:criteria_file],
    )

    if @extract.valid? && @extract.service_providers.present?
      if @extract.failures.length > 0
        flash[:warning] = 'Some criteria were invalid. Please check the results.'
      end
      save_to_file
      return render 'results'
    elsif @extract.errors.empty? && @extract.service_providers.empty?
      flash[:error] = 'No ServiceProvider rows were returned'
    elsif @extract.errors.empty? && @extract.teams.empty?
      flash[:error] = 'No Team rows were returned'
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

  # @return [String]
  # json output be a hash of two arrays (teams, service_providers)
  def save_to_file
    data = { teams: @extract.teams, service_providers: @extract.service_providers }
    begin
      File.open(@extract.filename, 'w') do |f|
        f.print data.to_json
      end
      flash[:success] = 'Extracted configs saved'
    rescue => err
      flash[:error] = "There was a problem writing to file: #{err}"
    end
  end

  def log_request
    log.extraction_request(action_name, extracts_params)
  end
end
