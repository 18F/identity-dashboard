class ExtractImporter
  attr_reader :file_name, :models
  attr_accessor :data

  def initialize(file_name)
    @file_name = file_name
  end

  def run
    validate_file unless data
    normalize_data unless models
    return errors if errors_any?

    check_for_conflicts
    save
  end

  private

  def validate_file
    raise ArgumentError, "File #{file_name} cannot be opened" unless File.readable?(file_name)

    File.open(file_name) do |file|
      @data = JSON.parse(file.read)
    end
  end

  def normalize_data
    @models = data.map { |config| ServiceProvider.new(**config) }

    # Assign these to the internal team and the first Login.gov Admin
    # We can easily change the team later
    models.each do |model|
      model.team = Team.internal_team
      model.user = Team.internal_team.users.first
    end
  end

  def errors
    models.each_with_object({}) do |model, error_list|
      model.valid?
      error_list[model.id] = model.errors
    end
  end

  def errors_any?
    errors.values.any? { |error| error.any? }
  end

  def check_for_conflicts

  end

  def save
    models.each &:save!
  end
end