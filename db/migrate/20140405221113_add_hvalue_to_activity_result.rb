class AddHvalueToActivityResult < ActiveRecord::Migration
  def change
    add_column :activity_results, :hash_value, :hstore
    add_column :activity_results, :scalar_value, :decimal, :precision => 10, :scale => 2, :default => 0
    add_hstore_index :activity_results, :hash_value
  end
end
