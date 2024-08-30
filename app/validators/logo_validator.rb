class LogoValidator < ActiveModel::Validator
  attr_reader :record

  MAX_LOGO_SIZE = 1.megabytes

  PNG_MIME_TYPE = 'image/png'.freeze
  SVG_MIME_TYPE = 'image/svg+xml'.freeze
  SP_VALID_LOGO_MIME_TYPES = [
    PNG_MIME_TYPE,
    SVG_MIME_TYPE,
  ].freeze
  SP_MIME_EXT_MAPPINGS = {
    PNG_MIME_TYPE => '.png',
    SVG_MIME_TYPE => '.svg',
  }.freeze

  def validate(record)
    logo_is_less_than_max_size
    logo_file_mime_typ
  end

  def logo_is_less_than_max_size
    return unless record.logo_file.attached?

    if logo_file.blob.byte_size > MAX_LOGO_SIZE
      errors.add(:logo_file, 'Logo must be less than 1MB')
      record.logo_file = nil
    end
  end

  def logo_file_mime_type
    return unless record.logo_file.attached?
    return if record.mime_type_valid?
    record.errors.add(
      :logo_file,
      "The file you uploaded (#{record.logo_file.filename}) is not a PNG or SVG",
    )
    record.logo_file = nil # rubocop:disable Lint/UselessAssignment
  end

  def mime_type_svg?
    record.logo_file.content_type.in?(SVG_MIME_TYPE)
  end

  def mime_type_valid?
    record.logo_file.content_type.in?(SP_VALID_LOGO_MIME_TYPES)
  end

  def logo_file_ext_matches_type
    return unless record.logo_file.attached?

    filename = record.logo_file.blob.filename.to_s

    file_ext = Regexp.new(/#{SP_MIME_EXT_MAPPINGS[logo_file.content_type]}$/i)

    return if filename.match(file_ext)

    errors.add(
      :logo_file,
      "The extension of the logo file you uploaded (#{filename}) does not match the content.",
    )
  end

  def validate_logo_svg
    return unless record.logo_file.attached?
    return unless mime_type_svg?

    svg = svg_xml

    return if svg.blank?

    svg_logo_has_size_attribute(svg)
    svg_logo_has_script_tag(svg)
  end

  def svg_logo_has_size_attribute(svg)
    return if svg_has_viewbox?(svg)
    
    record.errors.add(:logo_file, 
"The logo file you uploaded (#{logo_file.filename}) is missing a viewBox. Please add a viewBox attribute to your SVG and re-upload") # rubocop:disable Layout/LineLength
    record.logo_file = nil
  end

  def svg_logo_has_script_tag(svg)
    return unless svg.css('script').present?

    record.errors.add(:logo_file, 
"The logo file you uploaded (#{logo_file.filename}) contains one or more script tags. Please remove all script tags and re-upload") # rubocop:disable Layout/LineLength
    record.logo_file = nil
  end

  def svg_has_viewbox?(svg)
    svg.css(':root[viewBox]').present?
  end


  def svg_xml
    return if record.attachment_changes['logo_file'].blank?
    if record.attachment_changes['logo_file'].attachable.respond_to?(:open)
      Nokogiri::XML(File.read(record.attachment_changes['logo_file'].attachable.open))
    else
      Nokogiri::XML(File.read(record.attachment_changes['logo_file'].attachable[:io]))
    end
  end
end
