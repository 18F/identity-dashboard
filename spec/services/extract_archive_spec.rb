require 'rails_helper'

RSpec.describe ExtractArchive do
  it 'can add images to the archive' do
    sp = create(:service_provider)
    sp.logo_file = fixture_file_upload('logo.svg')
    sp.save!
    file = Tempfile.create binmode: true
    archive = ExtractArchive.new file
    archive.add_logos_from_service_providers [sp]
    archive.save
  end
end
