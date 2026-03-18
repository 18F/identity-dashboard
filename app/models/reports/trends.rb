module Reports
  # This class collates recent trend report data for a given service provider
  class Trends
    def initialize(service_provider, period = 3.weeks)
      # TODO: make data depend on service_provider
    end

    def active_users
      [
        { name: 'Total', data:
          dates.zip([213, 224, 245]).to_h },
        { name: 'Newly created', data:
          dates.zip([12, 12, 31]).to_h },
        { name: 'Existing accounts', data:
          dates.zip([201, 212, 214]).to_h },
      ]
    end

    def active_applications
      dates.zip([2, 3, 3])
    end

    private

    def dates
      ['Week 1', 'Week 2', 'Week 3']
    end
  end
end
