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

    if @extract.valid? && @extract.successes.present?
      if @extract.failures.length > 0
        flash[:warning] = 'Some criteria were invalid. Please check the results.'
      end
      save_to_file
      return render 'results'
    elsif @extract.errors.empty? && @extract.successes.empty?
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

  # @return [String]
  def save_to_file
    begin
      File.open(@extract.filename, 'w') do |f|
        data = @extract.successes.map do |sp|
          attributes = sp.attributes
          attributes['team_uuid'] = sp.team.uuid if sp.team.respond_to? :uuid
          attributes
        end
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
