# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config

  validates :config, presence: true

  def team
    config&.team || ''
  end

  def friendly_name
    config&.friendly_name || ''
  end

  def uuid
    config&.uuid
  end
end
