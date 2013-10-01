class AddSuperAdminFieldToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :is_admin, :boolean, default: false
    Role.where(name: 'Admin').update_all(is_admin: true, name: 'Super Admin')
  end
end
