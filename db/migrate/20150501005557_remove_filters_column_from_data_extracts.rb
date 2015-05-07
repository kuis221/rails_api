class RemoveFiltersColumnFromDataExtracts < ActiveRecord::Migration
  def change
    remove_column :data_extracts, :filters, :text
  end
end
