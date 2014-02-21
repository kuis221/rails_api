class AddLocalStartAndEndDatesToEvents < ActiveRecord::Migration
  def change
    add_column :events, :local_start_at, :datetime
    add_column :events, :local_end_at, :datetime
    execute "UPDATE events set local_start_at=(TIMEZONE('UTC', start_at) AT TIME ZONE timezone), local_end_at=(TIMEZONE('UTC', end_at) AT TIME ZONE timezone) where timezone is not null and timezone<>''"
  end
end
