require 'rails_helper'

describe ServiceConfigPolicy do
  let(:object) { WizardStep.new }

  permissions :new? do
    it_behaves_like 'allows all team members except Partner Readonly for `object`'
  end

  %i[index? create? edit? show? update? destroy?].each do |action_alias|
    context 'with RBAC' do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return true
      end

      permissions action_alias do
        it_behaves_like 'allows all team members except Partner Readonly for `object`'
      end
    end

    context 'without RBAC' do
      before do
        allow(IdentityConfig.store).to receive(:access_controls_enabled).and_return false
      end

      permissions action_alias do
        it 'allows anyone' do
          expect(described_class).to permit(build(:user))
        end
      end
    end
  end
end
