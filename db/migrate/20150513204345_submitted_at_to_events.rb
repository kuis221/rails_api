class SubmittedAtToEvents < ActiveRecord::Migration
  def change
    add_column :events, :submitted_at, :datetime
  end
end
