require 'rails_helper'

describe BasePolicy do
  let(:user) { build(:user) }
  let(:team) { build(:team) }

  permissions :index? do
    it 'does not allow user to list the index' do
      expect(BasePolicy).to_not permit(user)
    end
  end

  permissions :show? do
    it 'does not allow user to show an object' do
      expect(BasePolicy).to_not permit(user, team)
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
