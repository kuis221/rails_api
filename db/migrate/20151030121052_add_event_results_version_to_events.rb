class AddEventResultsVersionToEvents < ActiveRecord::Migration
  def change
    add_column :events, :results_version, :integer, default: 0
    Event.update_all(results_version: 0)
  end
end
