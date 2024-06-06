require 'rails_helper'

RSpec.describe BannerHelper do
  describe '#sort_banners_by_timing' do
    # Upcoming messages
    let(:banner_no_dates) { build(:banner,
      start_date: nil,
      end_date: nil
    )}
    let(:banner_no_end) { build(:banner,
      start_date: Date.today - 1.day,
      end_date: nil
    )}
    let(:banner_recent) { build(:banner,
      start_date: Date.today - 7.day,
      end_date: Date.today + 7.days
    )}
    let(:banner_recent_short) { build(:banner,
      start_date: Date.today - 1.day,
      end_date: Date.today + 6.days
    )}
    let(:banner_recent_long) { build(:banner,
      start_date: Date.today - 1.day,
      end_date: Date.today + 1.month
    )}
    let(:banner_old) { build(:banner,
      start_date: Date.today - 1.month,
      end_date: Date.today + 1.day 
    )}
    # Past messages
    let(:banner_past) { build(:banner,
      start_date: Date.today - 1.month,
      end_date: Date.today - 1.day
    )}
    let(:banner_past_short_mid) { build(:banner,
      start_date: Date.today - 12.days,
      end_date: Date.today - 1.day
    )}
    let(:banner_past_short) { build(:banner,
      start_date: Date.today - 7.days,
      end_date: Date.today - 1.day
    )}
    let(:banner_past_mid) { build(:banner,
      start_date: Date.today - 6.months,
      end_date: Date.today - 7.months
      )}
    let(:banner_past_far) { build(:banner,
      start_date: Date.today - 1.year,
      end_date: Date.today - 11.months
    )}

    it 'sorts messages by upcoming/current or past' do
      banners = [
        banner_recent_long, banner_old, banner_recent,
        banner_past, banner_past_far
      ]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_old, banner_recent, banner_recent_long],
        past: [banner_past, banner_past_far]
      })
    end

    it 'handles empty end_dates' do
      banners = [banner_no_end, banner_past]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_end],
        past: [banner_past]
      })
    end

    it 'handles empty start and end dates' do
      banners = [banner_no_end, banner_no_dates]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_dates, banner_no_end],
        past: []
      })
    end

    it 'sorts past messages by newest end date' do
      banners = [banner_past_far, banner_past,  banner_past_mid]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [],
        past: [banner_past, banner_past_mid, banner_past_far]
      })
    end

    it 'sorts past messages with the same end date by start date' do
      banners = [banner_past_short, banner_past, banner_past_short_mid]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [],
        past: [banner_past_short, banner_past_short_mid, banner_past]
      })
    end

    it 'sorts upcoming messages by newest start date' do
      banners = [banner_recent_long, banner_old, banner_recent]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_old, banner_recent, banner_recent_long],
        past: []
      })
    end

    it 'sorts upcoming messages with the same start date by end date' do
      banners = [banner_recent_long, banner_recent_short, banner_no_end]
      banner_hash = sort_banners_by_timing(banners)

      expect(banner_hash).to eq({
        upcoming: [banner_no_end, banner_recent_short, banner_recent_long],
        past: []
      })
    end
  end
end
