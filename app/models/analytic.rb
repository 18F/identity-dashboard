# The Analtyic tool is used for compiling SP Report data
class Analytic
  include ActiveModel::Model

  attr_accessor :date, :config

  delegate :team, :friendly_name, to: :config
end
