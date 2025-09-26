require 'rails_helper'

RSpec.describe FooterHelper do
  describe '#rendered_layout' do
    let(:user_signed_in?) { true }

    describe 'when user is signed in' do
      before do
        allow(self).to receive(:user_signed_in?).and_return(true)
      end

      it 'returns the path to the signed-in footer partial' do
        expect(rendered_layout).to eq 'layouts/footer_signed_in'
      end
    end

    describe 'when user is not signed in' do
      before do
        allow(self).to receive(:user_signed_in?).and_return(false)
      end

      it 'returns the path to the signed-out footer partial' do
        expect(rendered_layout).to eq 'layouts/footer_signed_out'
      end
    end
  end
end
