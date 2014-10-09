class RenameControllerFieldOnCustomFiltersTable < ActiveRecord::Migration
  def up
    rename_column :custom_filters, :controller, :apply_to
  end

  def down
  end
end
