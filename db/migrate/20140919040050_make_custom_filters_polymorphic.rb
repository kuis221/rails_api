class MakeCustomFiltersPolymorphic < ActiveRecord::Migration
  def change
    change_table :custom_filters do |t|
      t.references :owner, polymorphic: true
    end
    CustomFilter.update_all('owner_id=company_user_id, owner_type=\'CompanyUser\'')
    remove_column :custom_filters, :company_user_id
  end
end
