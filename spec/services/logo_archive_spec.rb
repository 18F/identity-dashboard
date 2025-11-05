require 'rails_helper'

RSpec.describe LogoArchive do
  it 'can add images to the archive' do
    sp = create(:service_provider)
    sp.logo_file = fixture_file_upload('logo.svg')
    sp.save!
    file = Tempfile.create binmode: true
    archive = LogoArchive.new file
    archive.add_service_providers [sp]
    archive.save
  end
end
