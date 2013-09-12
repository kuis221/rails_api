class AddOrderingFieldToKpis < ActiveRecord::Migration
  def change
    add_column :kpis, :ordering, :integer
  end
end
