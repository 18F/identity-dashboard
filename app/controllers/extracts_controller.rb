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
      criteria_list: extracts_params[:criteria_list],
      criteria_file: extracts_params[:criteria_file],
    )

    if @extract.valid?
      flash[@extract.error_level] = @extract.error_message

      respond_to do |format|
        format.html { render('results') }
        format.gzip { send_data extract_archive, filename: "#{@extract.filename}.tgz" }
      end and return
    end

    flash[:error] = 'No ServiceProvider rows were returned' if @extract.successes.empty?

    render 'index'
  end

  private

  def extract_archive
    output = ''
    in_memory_file = StringIO.new output
    archive = ExtractArchive.new(in_memory_file)
    archive.add_logos(@extract.logos)
    archive.add_json_file(
      @extract.to_json,
      'extract.json',
    )
    archive.save
    output
  end

  def extracts_params
    params.require(:extract).permit(
      :ticket,
      :criteria_file,
      :criteria_list,
    )
  end

  def log_request
    log.extraction_request(action_name, extracts_params)
  end
end
