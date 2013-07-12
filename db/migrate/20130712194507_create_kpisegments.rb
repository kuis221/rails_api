class CreateKpisegments < ActiveRecord::Migration
  def change
    create_table :kpisegments do |t|
      t.references :kpi
      t.string :text

      t.timestamps
    end
    add_index :kpisegments, :kpi_id
  end
end
