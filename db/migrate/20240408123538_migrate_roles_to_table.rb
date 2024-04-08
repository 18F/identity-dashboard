class MigrateRolesToTable < ActiveRecord::Migration[7.1]
  def up
    restricted_ic = Role.create(title: 'restricted_ic')
    ic = Role.create(title: 'ic')
    login_engineer = Role.create(title: 'login_engineer')


    User.all.each do |user|
      if user.admin?
        user.user_roles.create(role: login_engineer)
      elsif allowlisted_user?(user)
        user.user_roles.create(role: ic)
      else
        user.user_roles.create(role: restricted_ic)
      end
    end
  end

  def down
    Role.all.each do |role|
      role.users.each do |user|
        if role.title == 'login_engineer'
          role.update(admin: true)
        end
      end
    end
  end

  def allowlisted_user?(user)
    %w[.mil .gov .fed.us].any? do
      |domain| user.email.end_with? domain
    end
  end
end
