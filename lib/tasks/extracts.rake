namespace :extracts do
  desc <<~DESCRIPTION
  Imports extracted service providers from a JSON file. Provide the file name as a separate, final argument
  DESCRIPTION
  task import: [:environment] do
    file_name = ARGV.last
    ExtractImporter.new(file_name).import
  end
end