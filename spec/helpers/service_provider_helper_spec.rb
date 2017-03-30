require 'rails_helper'

describe ServiceProviderHelper do
  describe '#sp_logo_path' do
    context 'file name is present' do
      it 'returns the logo' do
        file = 'test.png'

        expect(sp_logo_path(file)).to match(
          /test.png/
        )
      end
    end

    context 'file name is nil' do
      it 'returns generic logo' do
        file = nil

        expect(sp_logo_path(file)).to match(
          /generic.svg/
        )
      end
    end
  end
end
