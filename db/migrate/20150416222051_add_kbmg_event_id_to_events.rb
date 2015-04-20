class AddKbmgEventIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :kbmg_event_id, :string
  end
end
