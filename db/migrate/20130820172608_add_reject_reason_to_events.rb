class AddRejectReasonToEvents < ActiveRecord::Migration
  def change
    add_column :events, :reject_reason, :text
  end
end
