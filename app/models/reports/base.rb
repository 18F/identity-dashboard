class Reports
  # This base class accepts an instance of Reports and allows for standard manipulation of its data
  class Base
    attr_reader :data

    def initialize(reports)
      @data = reports.data
    end

    private

    def to_chartkick_with_i18n_labels(keys = nil)
      keys ||= data.keys
      keys.each_with_object([]) do |key, results|
        next unless I18n.exists?("reports.#{key}")

        label = I18n.t("reports.#{key}")
        results.push([label, data[key]])
      end
    end
  end
end
