require 'rails_helper'
describe UserHelper do
  let(:user) { build(:user) }

  describe '#deadline' do
    it 'returns date in MM/DD/YYYY format' do
      created_at = Time.zone.now
      deadline = (created_at + 14.days).strftime('%m/%d/%Y')
      user.created_at = created_at
      expect(deadline(user)).to eq(deadline)
    end
  end

  describe('#can_delete_unconfirmed_users?') do
    it 'returns true if any users are unconfirmed and the current user is a Login.gov admin' do
      current_user = create(:user, :logingov_admin)
      expect(can_delete_unconfirmed_users?(current_user)).to be_truthy
    end

    it 'returns false if the current user is not an Login.gov admin' do
      current_user = build(:user)
      expect(can_delete_unconfirmed_users?(current_user)).to be_falsy
    end
  end

  describe '#sign_in_icon' do
    it 'returns success image for user that has signed in' do
      user.uuid = '3298uekefjlsejoeioeiur'
      expect(sign_in_icon(user)).to eq('alerts/success.svg')
    end

    it 'returns warning image for user that is unconfirmed' do
      user.created_at = 20.days.ago
      expect(sign_in_icon(user)).to eq('alerts/error.svg')
    end

    it 'returns error image for user that has not yet signed in' do
      user.created_at = 2.days.ago
      expect(sign_in_icon(user)).to eq('alerts/warning.svg')
    end
  end

  describe '#title' do
    it 'returns no title attribute for user that has signed in' do
      user.uuid = '3298uekefjlsejoeioeiur'
      expect(title(user)).to eq(nil)
    end

    it 'returns title attribute for unconfirmed user' do
      user.created_at = 20.days.ago
      expect(title(user)).to include('Sign-in deadline:')
    end

    it 'returns no title attribute for user yet to sign in' do
      user.created_at = 2.days.ago
      expect(title(user)).to eq(nil)
    end
  end

  describe '#caption' do
    it 'returns caption for user that has signed in' do
      user.uuid = '3209uekefjlsejoeioeiur'
      expect(caption(user)).to eq('User has signed in')
    end

    it 'returns caption for unconfirmed user' do
      user.created_at = 20.days.ago
      expect(caption(user)).to eq('Unconfirmed user')
    end

    it 'returns caption for user yet to sign in' do
      user.created_at = 2.days.ago
      expect(caption(user)).to eq('User has not yet signed in')
    end
  end

  describe '#alt' do
    it 'returns blank alt attribute for user that has signed in' do
      user.uuid = '3298uekefjlsejoeioeiur'
      expect(alt(user)).to eq('')
    end

    it 'returns alt attribute for unconfirmed user' do
      user.created_at = 20.days.ago
      expect(alt(user)).to include('Sign-in deadline:')
    end

    it 'returns blank alt attribute for user yet to sign in' do
      user.created_at = 2.days.ago
      expect(alt(user)).to eq('')
    end
  end
end
