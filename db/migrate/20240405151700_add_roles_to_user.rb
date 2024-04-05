class AddRolesToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :role, :integer, default: 0

    User.all.each do |user|
      if user.admin?
        user.update(role: 2)
      elsif allowlisted_user?(user)
        user.update(role: 1)
      else
        user.update(role: 0)
      end
    end
  end

  def allowlisted_user?(user)
    %w[.mil .gov .fed.us].any? do
      |domain| user.email.end_with? domain
    end
  end
end
