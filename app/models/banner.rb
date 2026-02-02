# Banner messages are persistent across all pages of the Portal.
class Banner < ApplicationRecord
  validates :message, presence: true
  validates :end_date,
            comparison: { greater_than: :start_date, message: 'must be after start date' },
            if: :start_date?,
            allow_blank: true
  validate :links_valid?

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

  def links_valid?
    links = Nokogiri::HTML(message).search('a')
    return true unless links.present?

    links.each do |link|
      href = link.attribute_nodes.detect { |attr| attr.name == 'href' }
      next unless href.value.present?

      begin
        uri = URI(href.value)
      rescue URI::InvalidURIError
        errors.add(:message, 'anchor link has invalid href') && next
      end
      host = uri.host
      errors.add(:message, "link has disallowed host: #{host}") if host && !host.end_with?('.gov')
    end

    false if errors.present?
  end
end
