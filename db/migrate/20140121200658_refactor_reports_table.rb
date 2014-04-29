class RefactorReportsTable < ActiveRecord::Migration
  def up
    rename_table :reports, :kpi_reports
    remove_column :kpi_reports, :type
    create_table :reports do |t|
      t.references :company
      t.string :name
      t.text :description
      t.boolean :active, default: true
      t.integer :created_by_id
      t.integer :updated_by_id
    end
  end

  def down
    drop_table :reports
    rename_table :kpi_reports, :reports
    add_column :reports, :type, :string
  end
end
