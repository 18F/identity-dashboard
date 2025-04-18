require 'rails_helper'

RSpec.describe BannerHelper do
  describe '#sort_banners_by_timing' do
    # Upcoming messages
    let(:banner_no_dates) do
      build(:banner,
      start_date: nil,
      end_date: nil)
    end
    let(:banner_no_end) do
      build(:banner,
      start_date: Time.zone.today - 1.day,
      end_date: nil)
    end
    let(:banner_today) do
      build(:banner,
      start_date: Time.zone.today,
      end_date: Time.zone.today)
    end
    let(:banner_recent) do
      build(:banner,
      start_date: Time.zone.today - 7.day,
      end_date: Time.zone.today + 7.days)
    end
    let(:banner_recent_short) do
      build(:banner,
      start_date: Time.zone.today - 1.day,
      end_date: Time.zone.today + 6.days)
    end
    let(:banner_recent_long) do
      build(:banner,
      start_date: Time.zone.today - 1.day,
      end_date: Time.zone.today + 1.month)
    end
    let(:banner_old) do
      build(:banner,
      start_date: Time.zone.today - 1.month,
      end_date: Time.zone.today + 1.day )
    end
    # Past messages
    let(:banner_past) do
      build(:banner,
      start_date: Time.zone.today - 1.month,
      end_date: Time.zone.today - 1.day)
    end
    let(:banner_past_short_mid) do
      build(:banner,
      start_date: Time.zone.today - 12.days,
      end_date: Time.zone.today - 1.day)
    end
    let(:banner_past_short) do
      build(:banner,
      start_date: Time.zone.today - 7.days,
      end_date: Time.zone.today - 1.day)
    end
    let(:banner_past_mid) do
      build(:banner,
      start_date: Time.zone.today - 6.months,
      end_date: Time.zone.today - 7.months)
    end
    let(:banner_past_far) do
      build(:banner,
      start_date: Time.zone.today - 1.year,
      end_date: Time.zone.today - 11.months)
    end

    it 'sorts messages by upcoming/current or past' do
      banners = [
        banner_recent_long, banner_old, banner_recent,
        banner_past, banner_past_far
      ]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_old, banner_recent, banner_recent_long],
        past: [banner_past, banner_past_far],
      })
    end

    it 'handles empty end_dates' do
      banners = [banner_no_end, banner_past]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_end],
        past: [banner_past],
      })
    end

    it 'handles empty start and end dates' do
      banners = [banner_no_end, banner_no_dates]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_dates, banner_no_end],
        past: [],
      })
    end

    it 'sorts past messages by newest end date' do
      banners = [banner_past_far, banner_past,  banner_past_mid]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [],
        past: [banner_past, banner_past_mid, banner_past_far],
      })
    end

    it 'sorts past messages with the same end date by start date' do
      banners = [banner_past_short, banner_past, banner_past_short_mid]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [],
        past: [banner_past_short, banner_past_short_mid, banner_past],
      })
    end

    it 'sorts upcoming messages by newest start date' do
      banners = [banner_recent_long, banner_old, banner_recent]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_old, banner_recent, banner_recent_long],
        past: [],
      })
    end

    it 'sorts upcoming messages with the same start date by end date' do
      banners = [banner_recent_long, banner_recent_short, banner_no_end]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_end, banner_recent_short, banner_recent_long],
        past: [],
      })
    end

    it 'puts banners ending today in upcoming' do
      banners = [banner_today]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_today],
        past: [],
      })
    end
  end

  describe '#get_active_banners' do
    let(:current_banner_one) do
      build(:banner, start_date: Time.zone.now.beginning_of_day - 2.days,
                     end_date: Time.zone.now.beginning_of_day + 2.days)
    end
    let(:current_banner_two) do
      build(:banner, start_date: Time.zone.now.beginning_of_day - 10.days,
                     end_date: Time.zone.now.beginning_of_day + 2.days)
    end
    let(:current_banner_three) do
      build(:banner, start_date: Time.zone.now.beginning_of_day - 5.days)
    end
    let(:banner_no_dates) do
      build(:banner)
    end
    let(:banner_no_end) do
      build(:banner,
      start_date: Time.zone.today - 1.day,
      end_date: nil)
    end
    let(:ended_banner) do
      build(:banner, start_date: Time.zone.now.beginning_of_day - 2.days,
                     end_date: Time.zone.now.beginning_of_day - 1.day)
    end

    before do
      current_banner_one.save
      current_banner_two.save
      current_banner_three.save
      banner_no_dates.save
      banner_no_end.save
      ended_banner.save
    end

    it 'only includes active banners' do
      displayed_banners = get_active_banners
      expect(displayed_banners.count).to eq(5)

      expect(displayed_banners).to include(current_banner_one)
      expect(displayed_banners).to include(current_banner_two)
      expect(displayed_banners).to include(current_banner_three)
      expect(displayed_banners).to include(banner_no_dates)
      expect(displayed_banners).to include(banner_no_end)
      expect(displayed_banners).to_not include(ended_banner)
    end

    it 'orders the banners by start_date' do
      displayed_banners = get_active_banners

      expect(displayed_banners.first).to eq(banner_no_dates)
      expect(displayed_banners.second).to eq(current_banner_two)
      expect(displayed_banners.third).to eq(current_banner_three)
      expect(displayed_banners.fourth).to eq(current_banner_one)
      expect(displayed_banners.fifth).to eq(banner_no_end)
    end
  end
end
