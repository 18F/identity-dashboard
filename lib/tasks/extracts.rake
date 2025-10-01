namespace :extracts do
  desc <<~DESCRIPTION
    Imports extracted service providers from a JSON file. Provide the file name as a separate, final argument
  DESCRIPTION
  task import: [:environment] do
    file_name = ARGV.last
    if file_name == 'extracts:import'
      raise ArgumentError, 'Provide the extracts file name as a separate, final argument'
    end

    importer = ServiceProviderImporter.new(file_name)
    importer.run
    importer.models.each do |model|
      puts "For issuer '#{model.issuer}'"
      puts "\tSaved? #{model.persisted? ? 'y' : 'n'}"
      puts "\tErrors: #{model.errors.full_messages.join(' ')}" if model.errors
    end
    puts '--- Done ---'
    puts 'Issuers with errors:'
    issuers_with_errors = importer.models.select { |rec| rec.errors.any? }.map do |rec|
      "'#{rec.issuer}'"
    end
    puts issuers_with_errors.any? ? issuers_with_errors.join(', ') : "\tnone"
  end
end
