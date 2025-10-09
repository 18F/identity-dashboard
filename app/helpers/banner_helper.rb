# Helper for Banner view
module BannerHelper
  def sort_banners_by_timing(banners)
    upcoming = []
    past = []
    now = DateTime.now
    # Put each banner into a Past or Upcoming bucket
    banners.each do |banner|
      if banner.end_date && DateTime.parse(banner.end_date.at_end_of_day.to_s) < now
        past.push(banner)
      else
        upcoming.push(banner)
      end
    end
    # Sort upcoming by start then end, past by end then start.
    # These are not DateTime values, they're ActiveSupport::TimeWithZone, and can be nil.
    upcoming.sort! do |a, b|
      a_int = a.start_date.to_f + a.end_date.to_f / 10000000000
      b_int = b.start_date.to_f + b.end_date.to_f / 10000000000
      a_int <=> b_int
    end
    past.sort! do |a, b|
      a_int = a.end_date.to_f + a.start_date.to_f / 10000000000
      b_int = b.end_date.to_f + b.start_date.to_f / 10000000000
      b_int <=> a_int
    end

    { upcoming:, past: }
  end

  def get_active_banners
    all_banners = Banner.all
    active_banners = all_banners.select { |banner| banner.active? == true }
    active_banners.sort! do |a, b|
      a_int = a.start_date.to_f + a.end_date.to_f / 10000000000
      b_int = b.start_date.to_f + b.end_date.to_f / 10000000000
      a_int <=> b_int
    end
  end
end
