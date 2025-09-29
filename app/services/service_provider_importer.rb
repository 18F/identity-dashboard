class ServiceProviderImporter
  attr_reader :file_name, :data, :models

  def initialize(file_name)
    @file_name = file_name
  end

  def run
    validate_file
    normalize_data
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
    create_missing_teams
    @models = data.map do |config|
      team = Team.find_by uuid: config['team_uuid'] if config['team_uuid']
      # Assign these to the internal team if the team info is missing.
      # We can easily change the team later.
      team ||= Team.internal_team

      sp = ServiceProvider.new(**config.except('team_uuid'))
      sp.team = team

      # Set the owning user as the first internal team user.
      # The portal doesn't require this column anymore, but it's still required by the schema.
      sp.user = Team.internal_team.users.first
      sp
    end
  end

  def create_missing_teams
    data.each do |config|
      team_uuid = config['team_uuid']
      next unless team_uuid
      next if Team.find_by(uuid: team_uuid)

      Team.create(
        uuid: team_uuid,
        name: "Created by importer #{team_uuid}",
        agency_id: config['agency_id'],
      )
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
