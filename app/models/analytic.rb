# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config, :data

  validate :is_valid?

  def uuid
    config&.uuid
  end

  def is_valid?
    if errors.present?
      return false
    elsif not config_valid?
      return false
    elsif not valid_date?
      return false
    else
      data_valid?
    end
  end

  private

  def config_valid?
    return true if uuid

    add_generic_error
    false
  end

  def data_valid?
    values = data.map(&:second)
    existing_values = values.filter(&:present?)

    return true if existing_values.present?

    add_data_error
    false
  end

  def valid_date?
    errors.add(:date, :invalid) and return false unless /\d{4}-\d{2}-\d{2}/.match? date

    begin
      Date.parse date
    rescue Date::Error
      add_generic_error
      return false
    end

    true
  end

  def add_data_error
    errors.add(:base, I18n.t('reports.errors.no_data'))
  end

  def add_generic_error
    errors.add(:base, I18n.t('reports.errors.generic'))
  end
end
