class CreateCustomFiltersCategories < ActiveRecord::Migration
  def change
    create_table :custom_filters_categories do |t|
      t.string :name
      t.references :company, index: true

      t.timestamps
    end
  end
end
