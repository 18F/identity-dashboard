class Group < ApplicationRecord
  belongs_to :agency

  has_many :service_providers, dependent: :nullify
  has_many :user_groups, dependent: :nullify
  has_many :users, through: :user_groups

  validates :name, presence: true, uniqueness: true

  after_update :update_service_providers

  def to_s
    name
  end

  def update_service_providers
    service_providers.each do |sp|
      sp.update(agency_id: agency.id) if agency
    end
  end
end
