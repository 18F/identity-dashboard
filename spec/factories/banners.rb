FactoryBot.define do
  factory :banner do
    message { 'MyText' }
    start_date { Time.zone.now.beginning_of_day - 1.day }
    end_date { Time.zone.now.end_of_day + 3.days }
  end
end
