class AddRejectedAtToEvents < ActiveRecord::Migration
  def change
    add_column :events, :rejected_at, :timestamp
  end
end
