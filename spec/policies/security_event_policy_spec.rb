require 'rails_helper'

describe SecurityEventPolicy do
  let(:admin) { create(:admin) }
  let(:ic_user) { create(:ic) }
  let(:restricted_user) { create(:restricted_ic) }
  let(:security_event) { create(:security_event, user: restricted_user) }

  permissions :manage_security_events? do
    it 'authorizes an admin' do
      expect(SecurityEventPolicy).to permit(admin, SecurityEvent)
    end
    it 'does not authorize an IC user' do
      expect(SecurityEventPolicy).to_not permit(ic_user, SecurityEvent)
    end
    it 'does not authorize other users' do
      expect(SecurityEventPolicy).to_not permit(restricted_user, SecurityEvent)
    end
  end

  permissions :show? do
    it 'gives access to an admin' do
      expect(SecurityEventPolicy).to permit(admin, security_event)
    end

    it 'does not give access to an IC user' do
      expect(SecurityEventPolicy).to_not permit(ic_user, security_event)
    end

    it 'does not give access to restricted ICs' do
      expect(SecurityEventPolicy).to_not permit(restricted_user, security_event)
    end
  end
end
