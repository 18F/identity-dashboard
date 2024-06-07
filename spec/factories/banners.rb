FactoryBot.define do
  factory :banner do
    message { 'MyText' }
    start_date { Time.now.beginning_of_day - 1.day }
    end_date { Time.now.end_of_day + 3.days }
  end
end
