class AddCategoryToCustomFilters < ActiveRecord::Migration
  def up
    add_column :custom_filters, :category_id, :integer, default: nil

    CustomFiltersCategory.find_each do |filter_category|
      CustomFilter.where(owner_type:'Company', owner_id: filter_category.company_id, group: filter_category.name).update_all(category_id: filter_category.id)
    end
  end

  def down
    CustomFiltersCategory.find_each do |filter_category|
      CustomFilter.where(owner_type:'Company', owner_id: filter_category.company_id, category_id: filter_category.id).update_all(group: filter_category.name)
    end

    remove_column :custom_filters, :category_id
  end
end
