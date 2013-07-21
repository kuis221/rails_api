class RemoveSlugColumnFromKpisTable < ActiveRecord::Migration
  def change
    remove_column :kpis, :slug
  end
end
