class RevertSlugToKpisTable < ActiveRecord::Migration
  def down
    remove_index :kpis, :slug
    remove_index :kpis, [:company_id, :slug], unique: true

    remove_column :kpis, :slug, :string
  end
end
