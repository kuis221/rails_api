class AddCompanyIdToBrands < ActiveRecord::Migration
  def change
    add_column :brands, :company_id, :integer
  end
end
