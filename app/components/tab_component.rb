# A tab component to allow view switching
class TabComponent < ViewComponent::Base
  attr_reader :tab_data, :opts

  # @param [Array] tab_data objects containing tab and panel info
  #  [{
  #    title: 'String tab title',
  #    id: 'String panel element ID',
  #    content: 'HTML/Partial',
  #  }],
  # @param [Object] opts options to be passed into HTML
  #  { class_name: 'String' }
  def initialize(tab_data:, opts: {})
    @tab_data, @opts = tab_data, opts
  end
end
