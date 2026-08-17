module Report
  # This base class accepts an instance of Reports and allows for standard manipulation of its data
  class Base
    attr_reader :data

    DEFAULT_OPTIONS = {
      colors: ['#1188ff', '#ff0000'],
    }.freeze

    def initialize(reports)
      @data = reports.data
    end

    def chart
      raise NotImplementedError
    end

    def total
      raise NotImplementedError
    end

    def as_array_with_i18n_labels(keys = nil)
      keys ||= data.keys
      keys.each_with_object([]) do |key, results|
        next unless I18n.exists?("reports.#{key}")

        label = I18n.t("reports.#{key}")
        results.push([label, data[key]])
      end
    end

    private

    def merge_options(chart_options)
      chart_options[:library] || chart_options[:library] = {}
      plot_opts = chart_options.dig(:library, :plotOptions)

      chart_options[:library].merge!({
        title: { align: 'left' },
        subtitle: {
          align: 'left',
          text: chart_options.delete(:subtitle),
        },
        accessibility: {
          screenReaderSection: {
            beforeChartFormat: "<h2>#{chart_options[:title]}</h2>",
          },
        },
        plotOptions: {
          series: {
            animation: false,
            colorByPoint: true,
          },
        },
        yAxis: {
          gridLineColor: '#888',
          minTickInterval: 1,
        },
      })
      chart_options[:library][:plotOptions].merge!(plot_opts) if plot_opts
      DEFAULT_OPTIONS.merge(chart_options)
    end
  end
end
