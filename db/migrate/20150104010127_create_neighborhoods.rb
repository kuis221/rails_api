class CreateNeighborhoods < ActiveRecord::Migration
  def change
    create_table :neighborhoods do |t|
      t.string :name
      t.string :city
      t.string :state
      t.string :county
      t.string :country
      t.text :geometry

      t.timestamps
    end
  end
end
