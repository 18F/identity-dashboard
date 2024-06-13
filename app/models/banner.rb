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
end
