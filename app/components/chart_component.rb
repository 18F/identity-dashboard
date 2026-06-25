# This class encapsulates the boilerplate and standard styling we want around most Chartkick charts
class ChartComponent < ViewComponent::Base
  # Chartkick is very good about this module only including the chart type methods
  attr_reader :title, :type, :data, :bottom_description, :top_description, :options

  # @param title [String]
  # @param type [Symbol|String] a valid Chartkick chart type
  # @param data data appropriate for the Chartkick chart type chosen
  # @param options [Hash] additional options; any not listed below will go through to Chartkick

  # @option options [String] :top_description a description that will show up just under the title
  # @option options [String] :bottom_description a description that will show up under the chart
  def initialize(title:, type:, data:, options:)
    (@title, @type, @data, @options) = [title, type, data, options]
    @top_description = options.delete(:top_description)
    @bottom_description = options.delete(:bottom_description)
  end

  def data_unavailable?
    data.blank?
  end
end
