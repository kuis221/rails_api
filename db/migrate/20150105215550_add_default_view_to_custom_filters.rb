class AddDefaultViewToCustomFilters < ActiveRecord::Migration
  def change
    add_column :custom_filters, :default_view, :boolean, default: false
  end
end
