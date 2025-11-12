require 'rails_helper'

RSpec.describe ExtractArchive do
  it 'can add images to the archive' do
    sp = create(:service_provider)
    sp.logo_file = fixture_file_upload('logo.svg')
    sp.save!
    expected_logo_filename = sp.logo_file.blob.filename
    file = Tempfile.create binmode: true
    archive = ExtractArchive.new file
    archive.add_logos_from_service_providers [sp]
    archive.save

    archive_test_output = `tar tzvf #{file.path}`
    expect(archive_test_output).to include(expected_logo_filename.to_s)

    # Be sure we're not looking at a file accidentally left from a previous test
    system "rm tmp/#{expected_logo_filename}"
    # Extract the file
    system("cd tmp; tar xzvf #{file.path}")
    expect(File.read("tmp/#{expected_logo_filename}")).to eq(sp.logo_file.download)
    # remove the expected temp file
    system "rm tmp/#{expected_logo_filename}"
  end

  it 'will not add an image for a config with no images' do
    sp = create(:service_provider)
    # Not adding an image here.

    file = Tempfile.create binmode: true
    archive = ExtractArchive.new file
    archive.add_logos_from_service_providers [sp]
    archive.save

    archive_test_output = `tar tzvf #{file.path}`
    expect(archive_test_output).to be_blank
  end
end
