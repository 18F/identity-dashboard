require 'rails_helper'

RSpec.describe Role, type: :model do
  it 'knows which roles are legacy admin' do
    expect(Role::SITE_ADMIN).to be_legacy_admin
    other_roles = Role::ACTIVE_ROLES.reject do |k,v|
      k == :logingov_admin
    end
    other_roles.each do |other_role|
      expect(Role.find_by(name: other_role)).not_to be_legacy_admin
    end
  end
end
