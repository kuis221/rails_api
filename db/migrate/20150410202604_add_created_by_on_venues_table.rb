class AddCreatedByOnVenuesTable < ActiveRecord::Migration
  def change
    add_column :venues, :created_by_id, :integer
    add_column :venues, :updated_by_id, :integer
  end
end
