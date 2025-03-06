require 'rails_helper'

describe MakeAdmin do
  let(:user_info)  { 'futureadmin@example.com,Robert,Smith' }
  let(:email)      { user_info.split(',')[0] }
  let(:first_name) { user_info.split(',')[1] }
  let(:last_name)  { user_info.split(',')[2] }

  subject { described_class.new(user_info) }

  before do
    allow(subject).to receive(:warn)
    allow(subject).to receive(:puts)
  end

  describe '#call' do
    context 'when the user does not exist' do
      it 'prints an info message and creates the user as login.gov admin' do
        expect(subject).to receive(:puts).with(
          "INFO: User \"#{email}\" not found; creating a new User.",
        )
        expect(subject).to receive(:puts).with(
          "SUCCESS: Promoted \"#{email}\" to Login.gov admin.",
        )

        subject.call

        user = User.find_by(
          email:,
          first_name:,
          last_name:,
        )

        expect(user).to_not be_nil
        expect(user.logingov_admin?).to eq(true)
      end
    end

    context 'when the user does exist and is not a Login admin' do
      it 'promotes the user to be an Login admin' do
        expect(subject).to receive(:puts).with(
          "SUCCESS: Promoted \"#{email}\" to Login.gov admin.",
        )

        user = User.create(
          email: email,
          first_name: first_name,
          last_name: last_name,
          admin: false,
        )

        subject.call

        user.reload

        expect(user.logingov_admin?).to eq(true)
      end
    end

    context 'when the user does exist and is a login.gov admin' do
      it 'prints an info message and does nothing' do
        expect(subject).to receive(:puts).with(
          "INFO: User \"#{email}\" already has Login.gov admin privileges.",
        )

        user = User.create(
          email: email,
          first_name: first_name,
          last_name: last_name,
          admin: true,
        )

        subject.call

        expect(user.logingov_admin?).to eq(true)
      end
    end

    context 'when the user info is empty' do
      let(:user_info) { nil }

      it 'prints a warn message and exits' do
        expect { subject.call }.to raise_error(RuntimeError, MakeAdmin::USAGE_WARNING)
      end
    end

    context 'when the user info is invalid' do
      let(:user_info) { 'buffalobuffalobuffalobuffalobuffalobuffalobuffalobuffalobuffalo' }

      it 'prints a warn message and exits' do
        expect { subject.call }.to raise_error(RuntimeError, MakeAdmin::USAGE_WARNING)
      end
    end
  end
end
