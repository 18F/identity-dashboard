# Banner messages are persistent across all pages of the Portal.
class Banner < ApplicationRecord
  validates :message, presence: true
  validates :end_date,
            comparison: { greater_than: :start_date, message: 'must be after start date' },
            if: :start_date?,
            allow_blank: true
  validate :link_allowed

  def started?
    start_date ? start_time < Time.zone.now : true
  end

  def ended?
    end_date && end_time < Time.zone.now
  end

  def active?
    started? && !ended?
  end

  def start_time
    start_date&.beginning_of_day || created_at.beginning_of_day
  end

  def end_time
    end_date.end_of_day
  end

  private

  def link_allowed
    href = message.match(/href=['|"]([a-zA-Z0-9\/:\-_.?#&%]+)['|"]/)
    return unless href

    host = URI(href[1]).host
    return true if !host || host.end_with?('.gov')

    errors.add(:message, "link has disallowed host: #{host}")
    false
  end
end
