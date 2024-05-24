require 'rails_helper'

RSpec.describe Banner, type: :model do
  let(:new_banner) { build(:banner)}

  it "is valid with basic parameters" do
    expect(new_banner.valid?).to be(true)
  end

  it "is not valid with a blank message" do
    new_banner.message = "    "
    expect(new_banner.valid?).to be(false)
  end

  it "errors out on the start date of start date is blank and end date is set" do
    new_banner.end_date = Time.zone.now
    expect(new_banner.valid?).to be(false)
    expect(new_banner.errors).to have_key(:start_date)
    expect(new_banner.errors).to_not have_key(:end_date)
  end


  it "is vaild if the start date is specified and the end date is not" do
    new_banner.start_date = Time.zone.now + [-1, 0, 1].sample.day
    new_banner.end_date = nil
    expect(new_banner.valid?).to be(true)
  end

  it "errors out on the end date if the end date is before the start date" do
    new_banner.start_date = Time.zone.now + 1.day
    new_banner.end_date = Time.zone.now - 1.day
    expect(new_banner.valid?).to be(false)
    expect(new_banner.errors).to_not have_key(:start_date)
    expect(new_banner.errors).to have_key(:end_date)
  end

  it "is valid with an end date after the start date" do
    new_banner.start_date = Time.zone.now - 1.day
    new_banner.end_date = Time.zone.now + 1.day
    expect(new_banner.valid?).to be(true)
  end

  describe "#active?" do
    let(:future_banner) { build(:banner, start_date: Date.today + 2.days) }
    let(:past_banner) { build(:banner, start_date: Date.today - 7.days, end_date: Date.today - 2.days) }

    it "is true for blank dates" do
      expect(new_banner.active?).to be(true)
    end

    it "is false if the start date is after today" do
      future_banner.end_date = nil
      expect(future_banner.active?).to be(false)
      future_banner.end_date = Date.today + 7.days
      expect(future_banner.active?).to be(false)
    end

    it "is false if the end date is before today" do
      expect(past_banner.active?).to be(false)
    end

    it "is true if the start date is before today and the end date is after" do
      past_banner.end_date = Date.today + 1.day
      expect(past_banner.active?).to be(true)
    end

    it "is true if the start date is before today and the end date is blank" do
      past_banner.end_date = nil
      expect(past_banner.active?).to be(true)
    end
  end
end
