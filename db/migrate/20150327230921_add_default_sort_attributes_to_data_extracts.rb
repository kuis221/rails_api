class AddDefaultSortAttributesToDataExtracts < ActiveRecord::Migration
  def change
    add_column :data_extracts, :default_sort_by, :string
    add_column :data_extracts, :default_sort_dir, :string
  end
end
