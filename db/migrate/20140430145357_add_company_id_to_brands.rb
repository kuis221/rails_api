class AddCompanyIdToBrands < ActiveRecord::Migration
  def change
    add_column :brands, :company_id, :integer
    add_index :brands, :company_id
  end
end
