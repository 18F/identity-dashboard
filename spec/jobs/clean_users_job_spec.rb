require 'rails_helper'

describe CleanUsersJob do
  it 'performs the job and schedules the next run' do
    interval = 10

    expect(CleanUsersService).to receive(:call)
    expect(described_class).to receive(:perform_in).with(interval, interval)

    described_class.new.perform(interval)
  end
end
