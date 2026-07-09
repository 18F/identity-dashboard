# The Analtyic represents the user's choices of which report to view
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config

  def uuid
    config&.uuid
  end

  def valid?
    config_valid? && date_valid?
  end

  def config_valid?
    return true if uuid

    add_generic_error
    false
  end

  def date_valid?
    unless /\d{4}-\d{2}-\d{2}/.match? date
      errors.add(:date, :invalid) unless errors.added?(:date, :invalid)
      return false
    end

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
