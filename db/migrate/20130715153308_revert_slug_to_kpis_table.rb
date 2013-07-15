class RevertSlugToKpisTable < ActiveRecord::Migration
  def down
    add_column :kpis, :slug, :string

    add_index :kpis, :slug
    add_index :kpis, [:company_id, :slug], unique: true

    Kpi.find_each(&:save)
  end
end
