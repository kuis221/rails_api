module CustomFiltersHelper
  def list_categories
    categories = CustomFiltersCategory.all.order('name')
    categories.pluck( :name, :id)
  end
end