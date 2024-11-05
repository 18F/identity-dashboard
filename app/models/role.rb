class Role < ApplicationRecord
  def self.seed
    Role.find_or_create_by(name: 'Login.gov Admin')
    Role.find_or_create_by(name: 'Partner Admin')
    Role.find_or_create_by(name: 'Partner Developer')
    Role.find_or_create_by(name: 'Partner Readonly')
  end

  # We should soon be able to remove this in favor of using Rails built-in methods
  # such as `accepts_nested_attributes_for`
  def self.radio_collection
    all.each_with_object({}) do |role, collection|
      collection[role.name] = role.legacy_admin?
    end
  end

  def legacy_admin?
    name == 'Login.gov Admin'
  end
end
