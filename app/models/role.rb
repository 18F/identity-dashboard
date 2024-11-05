class Role < ApplicationRecord
  def self.seed
    Role.find_or_create_by(name: 'Login.gov Admin')
    Role.find_or_create_by(name: 'Partner Admin')
    Role.find_or_create_by(name: 'Partner Developer')
    Role.find_or_create_by(name: 'Partner Readonly')
  end
end
