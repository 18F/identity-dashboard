module BannerHelper
  def splitBannersByTiming
    upcoming = []
    past = []
    now = DateTime.now
    # Put each banner into a Past or Upcoming bucket
    @banners.each do |banner|
      if banner.end_date && DateTime.parse(banner.end_date.to_s) < now
        past.push(banner)
      else
        upcoming.push(banner)
      end
    end
    # Sort upcoming by start then end, past by end then start.
    upcoming.sort! { |a,b| 
      a_int = (a.start_date.to_s.gsub(/\D/,'') + a.end_date.to_s.gsub(/\D/,'')).to_i
      b_int = (b.start_date.to_s.gsub(/\D/,'') + b.end_date.to_s.gsub(/\D/,'')).to_i
      a_int <=> b_int
    }
    past.sort! { |a,b| 
      a_int = (a.end_date.to_s.gsub(/\D/,'') + a.start_date.to_s.gsub(/\D/,'')).to_i
      b_int = (b.end_date.to_s.gsub(/\D/,'') + b.start_date.to_s.gsub(/\D/,'')).to_i
      b_int <=> a_int
    }

    return { upcoming: upcoming, past: past }
  end
end
