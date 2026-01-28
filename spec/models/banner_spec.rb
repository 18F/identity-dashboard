require 'rails_helper'

RSpec.describe Banner, type: :model do
  let(:new_banner) { build(:banner) }

  it 'is valid with basic parameters' do
    expect(new_banner.valid?).to be(true)
  end

  it 'is not valid with a blank message' do
    new_banner.message = '    '
    expect(new_banner.valid?).to be(false)
  end

  it 'does not allow links outside .gov domains' do
    new_banner.message = '<a href="https://mal.com">clickme</a>'
    expect(new_banner.valid?).to be_falsey

    new_banner.message = "<a href='https://mal.com'>clickme</a>"
    expect(new_banner.valid?).to be_falsey
  end

  it 'allows links to .gov domains' do
    new_banner.message = '<a href="https://good.gov/go">clickme</a>'
    expect(new_banner.valid?).to be_truthy

    new_banner.message = "<a href='https://good.gov/go'>clickme</a>"
    expect(new_banner.valid?).to be_truthy
  end

  it 'allows internal links' do
    new_banner.message = '<a href="service_providers/new">clickme</a>'
    expect(new_banner.valid?).to be_truthy

    new_banner.message = "<a href='service_providers/new'>clickme</a>"
    expect(new_banner.valid?).to be_truthy
  end

  it 'is valid if start date is blank and end date is set' do
    new_banner.start_date = nil
    new_banner.end_date = Time.zone.now
    expect(new_banner.valid?).to be(true)
  end

  it 'is vaild if the start date is specified and the end date is not' do
    new_banner.start_date = Time.zone.now + [-1, 0, 1].sample.day
    new_banner.end_date = nil
    expect(new_banner.valid?).to be(true)
  end

  it 'errors out on the end date if the end date is before the start date' do
    new_banner.start_date = Time.zone.now + 1.day
    new_banner.end_date = Time.zone.now - 1.day
    expect(new_banner.valid?).to be(false)
    expect(new_banner.errors).to_not have_key(:start_date)
    expect(new_banner.errors).to have_key(:end_date)
  end

  it 'is valid with an end date after the start date' do
    new_banner.start_date = Time.zone.now - 1.day
    new_banner.end_date = Time.zone.now + 1.day
    expect(new_banner.valid?).to be(true)
  end

  it 'can be more than 256 characters' do
    long_string = '12345678901234567890123456789012345678901234567890
    12345678901234567890123456789012345678901234567890
    12345678901234567890123456789012345678901234567890
    12345678901234567890123456789012345678901234567890
    12345678901234567890123456789012345678901234567890
    12345678901234567890123456789012345678901234567890'
    expect(new_banner.message).to_not eq(long_string)
    new_banner.message = long_string
    expect(long_string.length).to be > 256
    expect(new_banner.valid?).to be(true)
    new_banner.save!
    new_banner.reload
    expect(new_banner.message).to eq(long_string)
  end

  describe '#active?' do
    let(:future_banner) { build(:banner, start_date: Time.zone.now + 2.days) }
    let(:past_banner) do
      build(:banner,
        start_date: Time.zone.now - 7.days,
        end_date: Time.zone.now - 2.days)
    end

    it 'is true for blank dates' do
      expect(new_banner.active?).to be(true)
    end

    it 'is false if the start date is after today' do
      future_banner.end_date = nil
      expect(future_banner.active?).to be(false)
      future_banner.end_date = Time.zone.now + 7.days
      expect(future_banner.active?).to be(false)
    end

    it 'is false if the end date is before today' do
      expect(past_banner.active?).to be(false)
    end

    it 'is true if the start date is before today and the end date is after' do
      past_banner.end_date = Time.zone.now + 1.day
      expect(past_banner.active?).to be(true)
    end

    it 'is true if the start date is before today and the end date is blank' do
      past_banner.end_date = nil
      expect(past_banner.active?).to be(true)
    end
  end
end
