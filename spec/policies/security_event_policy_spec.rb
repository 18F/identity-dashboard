require 'rails_helper'

describe SecurityEventPolicy do
  let(:logingov_admin) { create(:logingov_admin) }
  let(:ic_user) { create(:user) }
  let(:restricted_user) { create(:restricted_ic) }
  let(:security_event) { create(:security_event, user: restricted_user) }

  permissions :manage_security_events? do
    it 'authorizes a login.gov admin' do
      expect(SecurityEventPolicy).to permit(logingov_admin, SecurityEvent)
    end

    it 'does not authorize an IC user' do
      expect(SecurityEventPolicy).to_not permit(ic_user, SecurityEvent)
    end

    it 'does not authorize other users' do
      expect(SecurityEventPolicy).to_not permit(restricted_user, SecurityEvent)
    end
  end
end
