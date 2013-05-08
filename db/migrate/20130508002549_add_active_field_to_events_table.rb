class AddActiveFieldToEventsTable < ActiveRecord::Migration
  def change
    add_column :events, :active, :boolean, default: true
  end
end
