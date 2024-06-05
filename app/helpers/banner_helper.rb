module BannerHelper
  def splitBannersByTiming
    upcoming = []
    past = []
    now = DateTime.now

    @banners.each do |banner|
      if banner.end_date && DateTime.parse(banner.end_date.to_s) < now
        past.push(banner)
      else
        upcoming.push(banner)
      end
    end

    return { upcoming: upcoming, past: past }
  end
end
