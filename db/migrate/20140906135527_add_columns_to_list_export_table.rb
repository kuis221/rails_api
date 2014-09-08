class AddColumnsToListExportTable < ActiveRecord::Migration
  def change
    change_table :list_exports do |t|
      t.text :url_options
    end
  end
end
