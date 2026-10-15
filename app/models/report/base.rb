module Report
  # This base class accepts an instance of Reports and allows for standard manipulation of its data
  class Base
    attr_reader :data

    # These are "library" options, because they're Highcharts-specific and Hicharts is
    # the library we're using with Chartkick.
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

    # These are Highcharts-specific options that we regularly need to override for specific charts.
    # If we're overriding them, the overrides need to be preserved and then merged in after
    # applying the `DEFAULT_LIBRAY_OPTIONS` above.
    LIBRARY_MERGE_KEYS = %i[chart plotOptions].freeze

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
      labeled_keys(keys).map { |key| [I18n.t("reports.#{key}"), data[key]] }
    end

    def rounded_percentage(float)
      (float * 100.0).round(2)
    end

    # Highcharts renders zero-value pie/donut slices as thin, hard-to-select
    # slivers that look non-zero at a glance. Using nil instead excludes the
    # slice from the chart while keeping it in the legend.
    def nil_if_zero(value)
      value&.nonzero?
    end

    def nil_zero_values(pairs)
      pairs.map { |(label, value)| [label, nil_if_zero(value)] }
    end

    private

    def labeled_keys(keys = nil)
      (keys || data.keys).select { |key| I18n.exists?("reports.#{key}") }
    end

    def merge_options(options)
      options[:library] ||= {}
      starting_library = options[:library].dup

      options[:library].merge!({
        title: { align: 'left' },
        subtitle: {
          align: 'left',
          text: options.delete(:subtitle),
        },
        caption: {
          useHTML: true,
          text: options.delete(:caption),
        },
        accessibility: {
          screenReaderSection: {
            beforeChartFormat: "<h2>#{options[:title]}</h2>",
          },
        },
        **DEFAULT_LIBRARY_OPTIONS,
      })

      LIBRARY_MERGE_KEYS.each do |key|
        options[:library][key] = options[:library][key].merge(starting_library[key] || {})
      end

      options
    end
  end
end
