class ServiceProviderDisabler
  attr_reader :file_name, :data, :models
  attr_accessor :dry_run

  def initialize(file_name)
    @file_name = file_name
    @models = []
  end

  def run
    validate_file unless data
    sp_issuers unless issuers
    return errors if errors_any?

    disable unless dry_run
    errors
  end

  private

  def errors_any?
    errors.values.any? { |error| error.any? }
  end

  def validate_file
    raise ArgumentError, "File #{file_name} cannot be opened" unless File.readable?(file_name)

    File.open(file_name) do |file|
      @data = JSON.parse(file.read)
    end
  end

  def sp_issuers
    @issuers ||= data.map{ |config| config['issuer'] }
  end

  def errors
    issuers.each_with_object({}) do |issuer, error_list|
      model = ServiceProvider.find_by(issuer: issuer)
      if model.blank?
        error_list[issuer] = ActiveRecord::RecordNotFound.new(issuer:)
      else
        models.push(model)
      end
    end
  end

  def disable
    models.each do |model|
      model.status = 'moved_to_prod'
      model.save
    end
  end
end
