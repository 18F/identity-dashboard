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
    doc = Nokogiri::HTML(message)
    links = doc.search('a')
    return true unless links.present?

    links.each do |link|
      href = link.attribute_nodes.detect { |attr| attr.name == 'href' }
      if href.value.present?
        begin
          uri = URI(href.value)
        rescue URI::InvalidURIError
          errors.add(:message, "anchor link has invalid href")
          return false
        end
        host = uri.host
        if host && !host.end_with?('.gov')
          errors.add(:message, "link has disallowed host: #{host}")
        end
      end
    end

    false if errors.present?
  end
end
