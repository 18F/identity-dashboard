require 'rails_helper'

describe PaperTrail::VersionPolicy::Scope do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:regular_user) { create(:user) }
  let(:scope_double) { instance_double(ActiveRecord::Relation) }

  it 'allows everything for login.gov admins' do
    resolution = described_class.new(logingov_admin, scope_double).resolve
    expect(resolution).to be(scope_double)
  end

  it 'allows nothing for non-admins' do
    expected_nothing = []
    allow(scope_double).to receive(:none).and_return(expected_nothing)
    resolution = described_class.new(regular_user, scope_double).resolve
    expect(resolution).to be(expected_nothing)
  end
end
