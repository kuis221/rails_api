class AddScoreDirtyFlagToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :score_dirty, :boolean, default: false
  end
end
