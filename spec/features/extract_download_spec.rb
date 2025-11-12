require 'rails_helper'

feature 'Extract Download' do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  before do
    login_as logingov_admin
  end

  let(:expected_ticket_number) { rand(1..1000).to_s }
  let(:expected_logo_name) { "logo_#{rand(1..1000)}.svg" }
  let(:sp_to_export) do
    sp = create(:service_provider, :ready_to_activate)
    sp.logo_file.attach(fixture_file_upload('logo.svg'))
    sp.logo = expected_logo_name
    sp.save!
    sp
  end

  it 'can deliver a download with the correct logo file' do
    visit extracts_path
    fill_in 'Ticket number', with: expected_ticket_number
    choose 'Teams'
    fill_in 'extract[criteria_list]', with: sp_to_export.team.id
    click_on 'Extract configs'
    click_on 'Download now'
    downloaded_file = StringIO.new page.body

    Minitar.unpack(Zlib::GzipReader.new(downloaded_file), 'tmp')
    expect(File.read("tmp/#{expected_logo_name}")).to eq(sp_to_export.logo_file.download)
  end

  it 'will include the correct attributes in the download' do
    visit extracts_path
    fill_in 'Ticket number', with: expected_ticket_number
    choose 'Teams'
    fill_in 'extract[criteria_list]', with: sp_to_export.team.id
    click_on 'Extract configs'
    click_on 'Download now'

    downloaded_file = StringIO.new page.body

    Minitar.unpack(Zlib::GzipReader.new(downloaded_file), 'tmp')
    json_from_archive = JSON.parse(File.read('tmp/extract.json'))
    expect(json_from_archive['service_providers'].count).to be 1
    exported_attributes = json_from_archive['service_providers'].first
    exported_attributes.keys.each do |attribute_key|
      next if attribute_key == 'team_uuid'
      next if attribute_key.end_with? '_at' # comparison of timestamps is flaky

      expect(exported_attributes[attribute_key]).to eq(sp_to_export[attribute_key]),
        "Key #{attribute_key} didn't match, value was: #{exported_attributes[attribute_key]}"
    end

    expect(exported_attributes['team_uuid']).to eq(sp_to_export.team.uuid)
  end

  after do
    # Clean up extracted files
    system('rm tmp/extract.json')
    system("rm tmp/#{expected_logo_name}")
  end
end
