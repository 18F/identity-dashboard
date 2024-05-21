require 'rails_helper'

RSpec.describe Banner, type: :model do
  let(:new_banner) { build(:banner)}

  it "is valid with basic parameters" do
    expect(banner.valid?).to be(true)
  end

  it "is not valid with a blank message" do
    banner.message = "    "
    expect(banner.valid?).to be(false)
  end
end
