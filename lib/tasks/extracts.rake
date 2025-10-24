namespace :extracts do # rubocop:disable Metrics/BlockLength
  confirm_msg = "\nPress enter or 'ctrl-c' to cancel. Press 'y' and then enter to continue:"
  import_usage = <<~DESCRIPTION
    Imports extracted service providers from a JSON file. Provide the file name as a separate, final argument.
    For a dry run, use:
      #{$PROGRAM_NAME} extracts:import -- --dry-run <filename.json>
  DESCRIPTION
  desc import_usage
  task import: [:environment] do
    file_name = ARGV.last
    if file_name.starts_with? 'extracts:import'
      puts "\n#{import_usage}"
      exit 1
    end

    importer = ServiceProviderImporter.new(file_name)

    # Always do a dry run first
    importer.dry_run = true

    errors = importer.run
    preview_import(importer, errors)
    errors_present = errors[:service_provider_errors].any? || errors[:team_errors].any?

    if !errors_present && !ARGV.include?('--dry-run')
      puts confirm_msg
      input = STDIN.gets.strip
      exit 1 unless /^y/i.match?(input)

      importer.dry_run = false
      errors = importer.run
      preview_import(importer, errors)
    end

    if ARGV.include?('--dry-run')
      puts '-- Dry Run --'
    else
      (saved_sps, unsaved_sps) = importer.service_providers.partition { |m| m.persisted? }
      output_models(saved_sps, unsaved_sps) { |models| puts issuers_list(models) }
      if saved_sps.any?
        export_models_to_file(saved_sps, "#{File.dirname(filename)}/exported_models.json")
      end

      (saved_teams, unsaved_teams) = importer.teams.partition { |m| m.persisted? }
      output_models(saved_teams, unsaved_teams) { |models| puts teams_list(models) }
    end
    puts '--- Done ---'
  end

  def output_models(saved, unsaved)
    if saved.any?
      puts 'Saved data for'
      yield(saved)
    end

    return unless unsaved.any?

    puts 'Did not save data for'
    yield(unsaved)
  end

  def preview_import(importer, errors)
    puts "\nIssuers to import:\n#{issuers_list(importer.service_providers)}\n"
    puts "\nTeams to import:\n#{teams_list(importer.teams)}\n"
    print_errors('team', errors[:team_errors])
    print_errors('issuer', errors[:service_provider_errors])
  end

  def preview_import(importer, errors)
    puts "\nIssuers to import:\n#{issuers_list(importer.service_providers)}\n"
    puts "\nTeams to import:\n#{teams_list(importer.teams)}\n"
    print_errors('team', errors[:team_errors])
    print_errors('issuer', errors[:service_provider_errors])
  end

  def print_errors(label, errors)
    errors.each do |key, errs|
      puts "\nFor #{label} '#{key}'"
      if errs&.any?
        puts "\tErrors: #{errs.full_messages.join('; ')}\n"
      else
        puts "\t— No errors —"
      end
    end
  end

  def teams_list(models)
    models.map { |model| "'#{model.name}: #{model.uuid}'" }.join("\n ")
  end

  def issuers_list(models)
    models.map { |model| "'#{model.issuer}'" }.join("\n ")
  end

  def export_models_to_file(models, file_name)
    File.open(file_name, 'w') { |f| f.puts models }
  end

  disable_usage = <<~DESCRIPTION
    Disables sandbox service providers that have been imported to Prod. Provide the source file name as a separate argument.

    Usage:
      #{$PROGRAM_NAME} extracts:disable -- {options} <filename.json>

    Options:
      --dry-run outputs affected service providers without making database changes.
  DESCRIPTION
  desc disable_usage
  task disable: [:environment] do
    file_name = ARGV.last
    if file_name.starts_with? 'extracts:disable'
      puts "\n#{disable_usage}"
      exit 1
    end

    disabler = ServiceProviderDisabler.new(file_name)

    # Always to a dry run first
    disabler.dry_run = true

    errors = disabler.run
    puts "\nIssuers to disable:\n#{issuers_list(disabler.models)}\n"
    print_errors(errors)
    unless errors.any? || ARGV.include?('--dry-run')
      puts confirm_msg
      input = STDIN.gets.strip
      exit 1 unless /^y/i.match?(input)

      disabler.dry_run = false
      errors = disabler.run
      print_errors(errors)
    end

    if ARGV.include?('--dry-run')
      puts '-- Dry Run --'
    else
      (saved, unsaved) = disabler.models.partition do |m|
        status = m.previous_changes[:status]
        status && status[1] == 'moved_to_prod'
      end
      puts "\nUpdated status for" if saved.any?
      puts issuers_list(saved)
      puts "\nDid not update status for" if unsaved.any?
      puts issuers_list(unsaved)
    end
    puts '--- Done ---'
  end
end
