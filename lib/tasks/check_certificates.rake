namespace :dashboard do
  desc 'Sample data for local development environment'
  task check_certificates: :environment do
    collection = {}

    ServiceProvider.all.each do |sp|
      collection[sp.issuer] = sp.certificate
    end

    sps = collection.keys.sort do |a, b|
      collection[a]&.not_after <=> collection[b]&.not_after
    end

    puts "\nExpiration                Issuer"
    sps.each do |sp|
      puts "#{collection[sp]&.expiration_time_to_colorized_s}   #{sp}"
    end
  end
end
