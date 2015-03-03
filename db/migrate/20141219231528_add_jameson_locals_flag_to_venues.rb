class AddJamesonLocalsFlagToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :jameson_locals, :boolean, default: false
    add_column :venues, :top_venue, :boolean, default: false
  end
end
