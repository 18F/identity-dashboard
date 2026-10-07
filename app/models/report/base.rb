module Report
  # This base class accepts an instance of Reports and allows for standard manipulation of its data
  class Base
    attr_reader :data

    DEFAULT_LIBRARY_OPTIONS = {
      chart: { styledMode: true, colorCount: 4 },
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

    def rounded_percentage(float)
      (float * 100.0).round(2)
    end

    private

    def merge_options(chart_options)
      chart_options[:library] ||= {}
      chart_options[:library] = merge_separately(chart_options[:library], [:plotOptions, :chart]) do
        {
          title: { align: 'left' },
          subtitle: {
            align: 'left',
            text: chart_options.delete(:subtitle),
          },
          caption: {
            useHTML: true,
            text: chart_options.delete(:caption),
          },
          accessibility: {
            screenReaderSection: {
              beforeChartFormat: "<h2>#{chart_options[:title]}</h2>",
            },
          },
          **DEFAULT_LIBRARY_OPTIONS,
        }
      end
      chart_options
    end

    def merge_separately(options, keys, &)
      later_options = {}
      keys.each do |key|
        later_options[key] = options[key] || {}
      end
      result = options.merge!(yield)
      keys.each do |key|
        result[key] ||= {}
        result[key] = result[key].merge(later_options[key])
      end
      result
    end
  end
end
