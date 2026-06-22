# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config, :data

  validate :valid?

  def uuid
    config&.uuid
  end

  def valid?
    if !config_valid? || !valid_date?
      false
    else
      data_valid?
    end
  end

  def config_valid?
    return true if uuid

    add_generic_error
    false
  end

  def data_valid?
    values = data.map(&:second)
    existing_values = values.filter(&:present?)

    return true if existing_values.present?

    errors.add(:base, I18n.t('reports.errors.no_data'))
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

  private

  def add_generic_error
    errors.add(:base, I18n.t('reports.errors.generic'))
  end
end
