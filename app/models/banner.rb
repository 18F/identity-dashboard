class Banner < ApplicationRecord
  validates :message, presence: true
  validates :start_date, presence: { message: 'must be set if end date is set' }, if: :end_date?
  validates :end_date, 
    comparison: { greater_than: :start_date, message: 'must be after start date' }, 
    if: :start_date?, 
    allow_blank: true

  def started?
    start_date ? start_date < Time.zone.now : true
  end

  def ended?
    end_date && end_date < Time.zone.now
  end

  def active?
    started? && !ended?
  end

  def active_banners
    all_banners = Banner.all
    active_banners = all_banners.select { |banner| banner.active? == true }
    active_banners.sort! { |a,b|
      a_int = a.start_date.to_f + a.end_date.to_f/10000000000
      b_int = b.start_date.to_f + b.end_date.to_f/10000000000
      a_int <=> b_int
    }

  end
end
