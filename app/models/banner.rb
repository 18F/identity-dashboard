class Banner < ApplicationRecord
  validates :message, presence: true
  validates :end_date, comparison: { greater_than: :start_date }, allow_blank: true
end
