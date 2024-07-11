require 'rails_helper'

describe HelpText do
  describe '#blank' do
    describe 'the text all filled in' do
      let(:help_text) do
        HelpText.new(text: {
          'sign_in'=> {'en'=>'<b>Some sign-in help text</b>'},
          'sign_up'=> {'en'=>'<b>Some sign-up help text</b>'},
          'forgot_password'=> {'en'=>'<b>Some forgot password help text</b>'},
        })
      end

      it 'returns false' do
        expect(help_text.blank?).to be false
      end
    end

    describe 'it is just empty strings' do
      let(:help_text) do
        HelpText.new(text: {
          'sign_in'=> {'en'=>''},
          'sign_up'=> {'en'=>''},
          'forgot_password'=> {'en'=>''},
        })
      end

      it 'returns true' do
        expect(help_text.blank?).to be true
      end
    end


    describe 'it is just empty strings with whitespace' do
      let(:help_text) do
        HelpText.new(text: {
          'sign_in'=> {'en'=>' '},
          'sign_up'=> {'en'=>' '},
          'forgot_password'=> {'en'=>'  '},
        })
      end

      it 'returns true' do
        expect(help_text.blank?).to be true
      end
    end

    describe 'it is just some empty hashes' do
      let(:help_text) do
        HelpText.new(text: {
          'sign_in'=> {},
          'sign_up'=> {},
          'forgot_password'=> {},
        })
      end

      it 'returns true' do
        expect(help_text.blank?).to be true
      end
    end
  end
end
