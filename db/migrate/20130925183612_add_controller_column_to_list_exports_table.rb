class AddControllerColumnToListExportsTable < ActiveRecord::Migration
  def change
    add_column :list_exports, :controller, :string
    add_column :list_exports, :progress, :integer, default: 0
    change_column :list_exports, :params, :text
    remove_column :list_exports, :list_class
  end
end
