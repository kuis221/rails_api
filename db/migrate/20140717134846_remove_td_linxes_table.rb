class RemoveTdLinxesTable < ActiveRecord::Migration
  def change
    drop_table :td_linxes
  end
end
