# Controller for ServiceProvider Extract tool page
class ExtractsController < AuthenticatedController
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
      respond_to do |format|
        format.html { return render('results') }
        format.gzip { send_data 'hi mom' }
      end
    elsif @extract.errors.empty? && @extract.service_providers.empty?
      flash[:error] = 'No ServiceProvider or Team rows were returned'
    end
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
    begin
      File.open(@extract.filename, 'w') do |f|
        sp_data = @extract.service_providers.map do |sp|
          attributes = sp.attributes
          attributes['team_uuid'] = sp.team.uuid
          # This is not portable between environments.
          attributes.delete 'remote_logo_key'
          attributes
        end
        data = { teams: @extract.teams, service_providers: sp_data }
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
