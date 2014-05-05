class AddColumnRowsValuesAndFiltersColumsToReports < ActiveRecord::Migration
  def change
    add_column :reports, :rows, :text
    add_column :reports, :columns, :text
    add_column :reports, :values, :text
    add_column :reports, :filters, :text
  end
end
