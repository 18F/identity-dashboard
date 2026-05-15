# A tab component to allow view switching
class TabComponent < ViewComponent::Base
  attr_reader :tabs

  def initialize(tabs:)
    @tabs = tabs
  end
end
