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
      it 'prints an info message and creates the user as an admin' do
        expect(subject).to receive(:puts).with(
          "INFO: User \"#{user_info}\" not found; creating a new User."
        )
        expect(subject).to receive(:puts).with(
          "SUCCESS: Promoted \"#{user_info}\" to admin."
        )

        subject.call

        user = User.find_by(
          email: email,
          first_name: first_name,
          last_name: last_name
        )

        expect(user).to_not be_nil
        expect(user.admin).to eq(true)
      end
    end

    context 'when the user does exist and is not an admin' do
      it 'promotes the user to be an admin' do
        expect(subject).to receive(:puts).with(
          "SUCCESS: Promoted \"#{user_info}\" to admin."
        )

        user = User.create(
          email: email,
          first_name: first_name,
          last_name: last_name,
          admin: false
        )

        subject.call

        user.reload

        expect(user.admin).to eq(true)
      end
    end

    context 'when the user does exist and is an admin' do
      it 'prints an info message and does nothing' do
        expect(subject).to receive(:puts).with(
          "INFO: User \"#{user_info}\" already has admin privileges."
        )

        user = User.create(
          email: email,
          first_name: first_name,
          last_name: last_name,
          admin: true
        )

        subject.call

        expect(user.admin).to eq(true)
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
