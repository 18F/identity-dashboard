# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config

  validate :config_valid?
  validate :valid_date?

  def uuid
    config&.uuid
  end

  def config_valid?
    return true if uuid

    add_generic_error
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
    errors.add(
      :base,
      'The link for that report was not valid. ' \
        'You can select a different report from the options below.',
    )
  end
end
