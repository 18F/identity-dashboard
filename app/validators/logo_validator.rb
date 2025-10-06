# Validator for partner logo uploads
class LogoValidator < ActiveModel::Validator
  attr_reader :record

  MAX_LOGO_SIZE = 50.kilobytes

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
    @record = record
    return unless record.pending_or_current_logo_data

    logo_is_less_than_max_size
    logo_file_mime_type
    logo_file_ext_matches_type
    validate_logo_svg
  end

  def logo_is_less_than_max_size
    changed_keys = record.changes.keys.map(&:to_s)
    return unless changed_keys.include?('logo') || changed_keys.include?('remote_logo_key')
    return unless record.logo_file.blob.byte_size > MAX_LOGO_SIZE

    record.errors.add(:logo_file, 'Logo must be less than 50kB')
  end

  def logo_file_mime_type
    return if mime_type_valid?

    record.errors.add(
      :logo_file,
      "The file you uploaded (#{record.logo_file.filename}) is not a PNG or SVG",
    )
  end

  def mime_type_svg?
    record.logo_file.content_type.in?(SVG_MIME_TYPE)
  end

  def mime_type_valid?
    record.logo_file.content_type.in?(SP_VALID_LOGO_MIME_TYPES)
  end

  def logo_file_ext_matches_type
    filename = record.logo_file.blob.filename.to_s

    file_ext = /#{SP_MIME_EXT_MAPPINGS[record.logo_file.content_type]}$/i

    return if filename.match(file_ext)

    record.errors.add(
      :logo_file,
      "The extension of the logo file you uploaded (#{filename}) does not match the content.",
    )
  end

  def validate_logo_svg
    return unless mime_type_svg?

    svg = ValidatingSvg.new(record.pending_or_current_logo_data)

    unless svg.has_viewbox?
      record.errors.add(:logo_file, I18n.t(
        'service_provider_form.errors.logo_file.no_viewbox',
        filename: record.logo_file.filename,
      ))
    end

    return unless svg.has_script_tag?

    record.errors.add(:logo_file, I18n.t(
      'service_provider_form.errors.logo_file.has_script_tag',
      filename: record.logo_file.filename,
    ))
  end
end
