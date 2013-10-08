class AddParentToMembershipsTable < ActiveRecord::Migration
  def change
    add_column :memberships, :parent_id, :integer
    add_column :memberships, :parent_type, :string

    add_index :memberships, [:parent_id, :parent_type]
  end
end
