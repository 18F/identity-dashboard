include Rails.application.routes.url_helpers

namespace :service_providers do
  task logo_blobs: [:environment] do |_task|
    ServiceProvider.find_each do |sp|
      if sp.logo_file.attached?
        puts "#{sp.issuer}: #{rails_blob_path(sp.logo_file, only_path: true)}"
      end
    end
  end
end
