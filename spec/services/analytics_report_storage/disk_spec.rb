require 'rails_helper'

RSpec.describe AnalyticsReportStorage::Disk do
  describe '#list' do
    it 'returns an empty array if the folder is missing' do
      missing_path = "garbage_folder_name #{rand(100.1000)}"
      expect(Dir.exist?(missing_path)).to be(false)
      subject = described_class.new({
        root: "garbage_folder_name #{rand(100.1000)}",
      })
      expect(subject.list).to eq([])
    end

    it 'returns a valid path to valid files if the folder exists' do
      valid_path = File.join(file_fixture_path, '..', 'reports')
      expect(Dir.exist?(valid_path)).to be(true)
      subject = described_class.new({
        root: valid_path,
      })
      results = subject.list ['urn:gov:gsa:openidconnect.profiles:sp:sso:dol_ebsa:lfdb']
      expect(results.count).to be 1
      file = File.new results.first.key
      expect(file.size).to be_positive
    end

    context 'with empty folders and empty files' do
      let(:missing_upload1) { 'report1' }
      let(:missing_upload2) { 'report2' }
      let(:valid_upload) { 'report3' }
      let(:valid_path) { File.join(file_fixture_path, '..', 'reports') }
      let(:empty_filename) { File.join(valid_path, "#{missing_upload1}.json") }
      let(:empty_dirname) { File.join(valid_path, "#{missing_upload2}.json") }
      let(:filename_with_data) { File.join(valid_path, "#{valid_upload}.json") }

      before do
        File.new(empty_filename, 'w').truncate(0)
        Dir.mkdir(empty_dirname)
        File.write(filename_with_data, '{}')
      end

      after do
        Dir.rmdir(empty_dirname)
        File.delete(empty_filename)
        File.delete(filename_with_data)
      end

      it 'skips folders and empty files' do
        subject = described_class.new({
          root: valid_path,
        })
        result = subject.list([missing_upload1, missing_upload2, valid_upload])
        expect(result.map(&:key)).to contain_exactly(filename_with_data)
      end
    end
  end
end
