class AddCompanyIdIndexToEvents < ActiveRecord::Migration
  def change
    add_index :events, :company_id
  end
end
