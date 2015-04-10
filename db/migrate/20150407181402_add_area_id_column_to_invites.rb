class AddAreaIdColumnToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :area_id, :integer
    add_index :invites, :area_id
  end
end
