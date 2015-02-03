class AddGroupToCustomFilters < ActiveRecord::Migration
  def change
    add_column :custom_filters, :group, :string
  end
end
