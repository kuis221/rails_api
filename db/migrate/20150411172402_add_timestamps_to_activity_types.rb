class AddTimestampsToActivityTypes < ActiveRecord::Migration
  def change
    add_column :activity_types, :created_by_id, :integer
    add_column :activity_types, :updated_by_id, :integer
  end
end
