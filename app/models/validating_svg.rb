# Model for Validating SVG
class ValidatingSvg
  attr_reader :svg

  def initialize(string_buffer)
    @svg = Nokogiri::XML(string_buffer)
  end

  def has_script_tag?
    svg.css('script').present?
  end

  def has_viewbox?
    svg.css(':root[viewBox]').present?
  end
end
