class RemoveGroupToCustomFilters < ActiveRecord::Migration
  def change
    remove_column :custom_filters, :group
  end
end
