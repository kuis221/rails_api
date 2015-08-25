class AddParamsToDataExtracts < ActiveRecord::Migration
  def change
    add_column :data_extracts, :params, :text
  end
end
