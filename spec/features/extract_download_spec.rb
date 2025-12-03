require 'rails_helper'

feature 'Extract Download' do
  let(:logingov_admin) { create(:user, :logingov_admin) }

  before do
    login_as logingov_admin
  end

  let(:expected_ticket_number) { rand(1..1000).to_s }
  let(:expected_logo_name) { "logo_#{rand(1..1000)}.svg" }
  let(:sp_to_export) do
    sp = create(:service_provider, :ready_to_activate, agency_id: 9)
    team = sp.team
    team.agency_id = 9
    team.save!
    sp.logo_file.attach(fixture_file_upload('logo.svg'))
    sp.logo = expected_logo_name
    sp.save!
    sp
  end

  it 'has no download link with invalid criteria' do
    visit extracts_path
    fill_in 'Ticket number', with: expected_ticket_number
    choose 'Teams'
    fill_in 'extract[criteria_list]', with: Team.last.id + rand(10.1000)
    click_on 'Extract configs'
    expect(page).to have_content('No ServiceProvider or Team rows were returned')
    expect(page).to_not have_button('Download configs')
    expect(page).to_not have_link('Download configs')
  end

  context 'when downloading' do
    before do
      visit extracts_path
      fill_in 'Ticket number', with: expected_ticket_number
      choose 'Teams'
      fill_in 'extract[criteria_list]', with: sp_to_export.team.id
      click_on 'Extract configs'
      click_on 'Download configs'
    end

    it 'can deliver a download with the correct logo file' do
      downloaded_file = StringIO.new page.body

      Minitar.unpack(Zlib::GzipReader.new(downloaded_file), 'tmp')
      expect(File.read("tmp/#{sp_to_export.id}_#{expected_logo_name}")).to eq(sp_to_export.logo_file.download)
    end

    it 'will include the correct attributes in the download' do
      downloaded_file = StringIO.new page.body

      Minitar.unpack(Zlib::GzipReader.new(downloaded_file), 'tmp')
      json_from_archive = JSON.parse(File.read('tmp/extract.json'))

      expect(json_from_archive['service_providers'].count).to be 1
      exported_attributes = json_from_archive['service_providers'].first

      # Test attributes that don't behave like the others
      expect(exported_attributes['team_uuid']).to eq(sp_to_export.team.uuid)
      expect(exported_attributes['logo']).to eq("#{sp_to_export.id}_#{expected_logo_name}")

      exported_attributes.keys.each do |attribute_key|
        next if attribute_key.end_with? '_at' # comparison of timestamps is flaky

        # Skip attributes already tested
        next if attribute_key == 'team_uuid'
        next if attribute_key == 'logo'

        expect(exported_attributes[attribute_key]).to eq(sp_to_export[attribute_key]),
          "Key #{attribute_key} didn't match, value was: #{exported_attributes[attribute_key]}"
      end
    end
  end

  after do
    # Clean up extracted files
    system('rm tmp/extract.json')
    system("rm tmp/#{sp_to_export.id}_#{expected_logo_name}")
  end
end
