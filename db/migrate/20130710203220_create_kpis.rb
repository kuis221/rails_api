class CreateKpis < ActiveRecord::Migration
  def change
    create_table :kpis do |t|
      t.string :name
      t.text :description
      t.string :kpi_type
      t.string :capture_mechanism
      t.references :company
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
  end
end
