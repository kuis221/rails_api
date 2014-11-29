class AddGroupToCustomFilters < ActiveRecord::Migration
  def change
    add_column :custom_filters, :group, :string
    CustomFilter.reset_column_information
    CustomFilter.update_all(group: CustomFilter::SAVED_FILTERS_NAME)
  end
end
