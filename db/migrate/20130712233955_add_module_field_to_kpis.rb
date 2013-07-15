class AddModuleFieldToKpis < ActiveRecord::Migration
  def change
    add_column :kpis, :module, :string, null: false, default: "custom"
  end
end
