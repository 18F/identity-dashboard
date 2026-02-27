require 'rails_helper'

describe HelpTextPresenter do
  let(:user) { create(:user) }
  let(:sp) { build(:service_provider, help_text:) }
  let(:help_text) { {} }

  subject { described_class.new(HelpText.lookup(service_provider: sp), user) }

  describe '#readonly_help_text' do
    describe 'a non-admin user' do
      it 'returns true' do
        expect(subject.readonly_help_text?).to be true
      end
    end

    describe 'a login.gov admin user' do
      let(:user) { create(:logingov_admin) }

      it 'returns false' do
        expect(subject.readonly_help_text?).to be false
      end
    end
  end

  describe '#show_minimal_help_text_element' do
    context 'when not a login.gov admin user' do
      describe 'when help text exists' do
        describe 'and is not blank' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => '<b>Some sign-in help text</b>' },
              'sign_up' => { 'en' => '<b>Some sign-up help text</b>' },
              'forgot_password' => { 'en' => '<b>Some forgot password help text</b>' },
            }
          end

          it 'returns false' do
            expect(
              subject.show_minimal_help_text_element?,
            ).to be false
          end
        end

        describe 'it is just empty strings' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => '' },
              'sign_up' => { 'en' => '' },
              'forgot_password' => { 'en' => '' },
            }
          end

          it 'returns true' do
            expect(
              subject.show_minimal_help_text_element?,
            ).to be true
          end
        end

        describe 'it is just empty strings with whitespace' do
          let(:help_text) do
            {
              'sign_in' => { 'en' => ' ' },
              'sign_up' => { 'en' => ' ' },
              'forgot_password' => { 'en' => '  ' },
            }
          end

          it 'returns true' do
            expect(
              subject.show_minimal_help_text_element?,
            ).to be true
          end
        end

        describe 'it is just some empty hashes' do
          let(:help_text) do
            {
              'sign_in' => {},
              'sign_up' => {},
              'forgot_password' => {},
            }
          end

          it 'returns true' do
            expect(
              subject.show_minimal_help_text_element?,
            ).to be true
          end
        end
      end
    end

    describe 'a login.gov admin' do
      let(:user) { create(:logingov_admin) }
      let(:help_text) { {} }

      it 'returns false' do
        expect(subject.show_minimal_help_text_element?).to be false
      end
    end
  end
end
