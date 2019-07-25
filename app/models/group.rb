class Group < ApplicationRecord
  belongs_to :agency

  has_many :service_providers
  has_many :user_groups
  has_many :users, through: :user_groups

  validates :name, presence: true, uniqueness: true

  after_update :update_service_providers

  def to_s
    name
  end

  def update_service_providers
    service_providers.each do |s|
      s.update_attributes(agency_id: agency.id)
    end
  end
end
