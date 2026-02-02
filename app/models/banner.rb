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
    return true unless html_links.present?

    html_links.each do |link|
      begin
        uri = uri_in_anchor(link)
      rescue URI::InvalidURIError
        errors.add(:message, 'anchor link has invalid href')
      end
      next unless uri

      host = uri.host
      errors.add(:message, "link has disallowed host: #{host}") if host && !host.end_with?('.gov')
    end
  end

  def html_links
    @html_links ||= Nokogiri::HTML(message).search('a')
  end

  # @param link {HTML anchor tag}
  # @return parsed URI || nil
  # @raise URI::InvalidURIError
  def uri_in_anchor(link)
    href = link.attribute_nodes.detect { |attr| attr.name == 'href' }
    uri = href&.value
    return nil unless uri

    URI(uri)
  end
end
