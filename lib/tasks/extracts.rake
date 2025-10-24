# rubocop:disable Metrics/BlockLength
namespace :extracts do
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
    puts "\nIssuers to import:\n#{issuers_list(importer.models)}\n"
    print_errors(errors)

    unless errors.any? || ARGV.include?('--dry-run')
      puts confirm_msg
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
      if saved.any?
        puts 'Saved data for'
        puts issuers_list(saved)
        export_models_to_file saved, "#{File.dirname(file_name)}/exported_models.json"
      end
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
    models.map { |model| "'#{model.issuer}'" }.join("\n")
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
# rubocop:enable Metrics/BlockLength
