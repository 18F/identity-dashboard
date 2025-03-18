require 'spec_helper'
require 'pry-byebug'
require File.expand_path('../../lib/deploy/activate', __dir__)

describe Deploy::Activate do
  let(:root) { File.expand_path('../../', __dir__) }
  let(:runner) { described_class.new(root:) }

  after do
    `/bin/rm -rf #{File.expand_path('../../identity-idp-config', __dir__)}`
    Deploy::Activate::FILES_TO_LINK.each do |file|
      `/bin/rm #{File.expand_path("../../config/#{file}.yml", __dir__)}`
    end
  end

  it 'does something' do
    runner.run
    Deploy::Activate::FILES_TO_LINK.each do |file|
      source_path = File.expand_path("../../identity-idp-config/#{file}.yml", __dir__)
      expect(File).to be_file(source_path), "Did not find source file at #{source_path}"

      symlink_path = File.expand_path("../../config/#{file}.yml", __dir__)
      expect(File).to be_symlink(symlink_path), "Did not find symlink at #{symlink_path}"
    end
  end
end
