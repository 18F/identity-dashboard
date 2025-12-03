require 'rails_helper'

RSpec.describe ExtractArchive do
  let(:tempfile) { Tempfile.create binmode: true }
  let(:altered_filename) { "#{rand(1..1000)}_logo" }

  subject(:archive) { ExtractArchive.new tempfile }

  after do
    # Be sure we don't actually leave files behind that invalidate the next test run
    system 'rm tmp/*.svg tmp/*.png'
    system "rm tmp/#{altered_filename}"
  end

  it 'can add images to the archive' do
    sp = create(:service_provider)
    sp.logo_file = fixture_file_upload('logo.svg')
    sp.logo = 'logo.svg'
    sp.save!
    expected_logo_filename = sp.logo_file.blob.filename
    archive.add_logos [{ attachment: sp.logo_file, filename: expected_logo_filename }]
    archive.save

    archive_test_output = `tar tzvf #{tempfile.path}`
    expect(archive_test_output).to include(expected_logo_filename.to_s)

    # Extract the file
    system("cd tmp; tar xzvf #{tempfile.path}")
    expect(File.read("tmp/#{expected_logo_filename}")).to eq(sp.logo_file.download)
  end

  it 'can add multiple images' do
    sp_with_svg = create(:service_provider)
    sp_with_svg.logo_file = fixture_file_upload('logo.svg')
    sp_with_svg.logo = 'logo.svg'
    sp_with_svg.save!

    sp_with_conflicting_file = create(:service_provider)
    sp_with_conflicting_file.logo_file = fixture_file_upload(['logo.png', 'logo.svg'].sample)
    sp_with_conflicting_file.save!

    sp_with_png = create(:service_provider)
    sp_with_png.logo_file = fixture_file_upload('logo.png')
    sp_with_png.logo = 'logo.png'
    sp_with_png.save!

    archive.add_logos [
      { attachment: sp_with_svg.logo_file, filename: 'logo.svg' },
      { attachment: sp_with_conflicting_file.logo_file, filename: altered_filename },
      { attachment: sp_with_png.logo_file, filename: 'logo.png' },
    ]
    archive.save

    # Extract the file
    system("cd tmp; tar xzvf #{tempfile.path}")
    expect(File.read('tmp/logo.svg')).to eq(sp_with_svg.logo_file.download)
    expect(File.read('tmp/logo.png', binmode: true)).to eq(sp_with_png.logo_file.download)
    expect(File.read(
      "tmp/#{altered_filename}",
      binmode: true,
    )).to eq(sp_with_conflicting_file.logo_file.download)
  end
end
