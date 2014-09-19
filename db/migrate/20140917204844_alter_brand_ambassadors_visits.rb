class AlterBrandAmbassadorsVisits < ActiveRecord::Migration
  def change
    remove_column :brand_ambassadors_visits, :name
    add_column :brand_ambassadors_visits, :visit_type, :string
    add_column :brand_ambassadors_visits, :brand_id, :integer
    add_column :brand_ambassadors_visits, :area_id, :integer
    add_column :brand_ambassadors_visits, :city, :string

    add_index :brand_ambassadors_visits, :brand_id
    add_index :brand_ambassadors_visits, :area_id
  end
end
