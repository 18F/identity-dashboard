namespace :extracts do # rubocop:disable Metrics/BlockLength
  import_usage = <<~DESCRIPTION
    Imports extracted service providers from a JSON file. Provide the file name as a separate, final argument.
    For a dry run, use:
      #{$PROGRAM_NAME} extracts:import -- --dry-run <filename.json>
  DESCRIPTION
  desc import_usage
  task import: [:environment] do
    file_name = ARGV.last
    raise ArgumentError, import_usage if file_name.starts_with? 'extracts:import'

    importer = ServiceProviderImporter.new(file_name)

    # Always do a dry run first
    importer.dry_run = true

    errors = importer.run
    puts "\nIssuers to import:\n#{issuers_list(importer.service_providers)}\n"
    puts "\nTeams to import:\n#{teams_list(importer.teams)}\n"
    print_team_errors(errors[:team_errors])
    print_sp_errors(errors[:service_provider_errors])

    unless (errors[:service_provider_errors].any? || errors[:team_errors].any?) || ARGV.include?('--dry-run')
      puts "\nPress enter or 'ctrl-c' to cancel. Press 'y' and then enter to continue:"
      input = STDIN.gets.strip
      exit 1 unless /^y/i.match?(input)

      importer.dry_run = false
      errors = importer.run
      print_team_errors(errors[:team_errors])
      print_sp_errors(errors[:service_provider_errors])
    end

    if ARGV.include?('--dry-run')
      puts '-- Dry Run --'
    else
      (saved_sps, unsaved_sps) = importer.service_providers.partition { |m| m.persisted? }
      output_service_providers(saved_sps, unsaved_sps)
      (saved_teams, unsaved_teams) = importer.teams.partition { |m| m.persisted? }
      output_teams(saved_teams, unsaved_teams)

    end
    puts '--- Done ---'
  end

  def output_teams(saved, unsaved)
      puts 'Saved data for' if saved.any?
      puts teams_list(saved)
      puts 'Did not save data for' if unsaved.any?
      puts teams_list(unsaved)
  end

  def output_service_providers(saved, unsaved)
      puts 'Saved data for' if saved.any?
      puts issuers_list(saved)
      puts 'Did not save data for' if unsaved.any?
      puts issuers_list(unsaved)
  end

  def print_sp_errors(errors)
    errors.each do |issuer, errors|
      puts "For issuer '#{issuer}'"
      if errors
        puts "\tErrors: #{errors.full_messages.join(' ')}"
      else
        puts "\t— No errors —"
      end
    end
  end

  def print_team_errors(errors)
    errors.each do |uuid, errors|
      puts "For team '#{uuid}'"
      if errors
        puts "\tErrors: #{errors.full_messages.join(' ')}"
      else
        puts "\t— No errors —"
      end
    end
  end

  def teams_list(models)
    models.map { |model| "'#{model.name}: #{model.uuid}'" }.join(', ')
  end

  def issuers_list(models)
    models.map { |model| "'#{model.issuer}'" }.join(', ')
  end
end
