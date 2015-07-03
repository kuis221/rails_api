class AddApprovedAtToEvents < ActiveRecord::Migration
  def change
    add_column :events, :approved_at, :datetime
  end
end
