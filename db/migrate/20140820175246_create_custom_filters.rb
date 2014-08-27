class CreateCustomFilters < ActiveRecord::Migration
  def change
    create_table :custom_filters do |t|
      t.references :company_user
      t.string :name
      t.string :controller
      t.text :filters

      t.timestamps
    end
    add_index :custom_filters, :company_user_id
  end
end
