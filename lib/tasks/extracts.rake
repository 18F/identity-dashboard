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
    puts "\nIssuers to import:\n#{issuers_list(importer.models)}\n"
    print_errors(errors)

    unless errors.any? || ARGV.include?('--dry-run')
      puts "\nPress enter or 'ctrl-c' to cancel. Press 'y' and then enter to continue:"
      input = STDIN.gets.strip
      exit 1 unless /^y/i.match?(input)

      importer.dry_run = false
      errors = importer.run
      print_errors(errors)
    end

    if ARGV.include?('--dry-run')
      puts '-- Dry Run --'
    else
      (saved, unsaved) = importer.models.partition { |m| m.persisted? }
      puts 'Saved data for' if saved.any?
      puts issuers_list(saved)
      puts 'Did not save data for' if unsaved.any?
      puts issuers_list(unsaved)
    end
    puts '--- Done ---'
  end

  def print_errors(errors)
    errors.each do |issuer, errors|
      puts "For issuer '#{issuer}'"
      if errors
        puts "\tErrors: #{errors.full_messages.join(' ')}"
      else
        puts "\t— No errors —"
      end
    end
  end

  def issuers_list(models)
    models.map { |model| "'#{model.issuer}'" }.join(', ')
  end
end
