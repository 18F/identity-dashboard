# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config

  validates :config, presence: true

  def uuid
    config&.uuid
  end
end
