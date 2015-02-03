module CustomFiltersHelper
  def list_categories
    CustomFiltersCategory.all.order('name').pluck( :name, :id).concat([['Create New Category', 'new', class: 'new_category_bt']])
  end
end