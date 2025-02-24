require 'rails_helper'

describe BasePolicy do
  let(:user) { build(:user) }
  let(:sp) { build(:service_provider) }

  permissions :index? do
    it 'does not allow user to list the index' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :show? do
    it 'depends on the scope' do
      expect("#{sp.class}Policy::Scope".constantize).to receive(:new).and_call_original
      expect(BasePolicy).to_not permit(user, sp)
    end
  end

  permissions :create? do
    it 'does not allow user to create an object' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :new? do
    it 'does not allow user to see a new object form' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :update? do
    it 'does not allow user to update an object' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :edit? do
    it 'does not allow user to edit an object' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :destroy? do
    it 'does not allow user to destroy an object' do
      expect(BasePolicy).to_not permit(user)
    end
  end
end
