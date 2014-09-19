class AddGroupToCustomFilters < ActiveRecord::Migration
  def change
    add_column :custom_filters, :group, :string
    CustomFilter.update_all(group: 'Saved Filters')
  end
end
