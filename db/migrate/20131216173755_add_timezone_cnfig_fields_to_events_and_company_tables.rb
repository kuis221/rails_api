class AddTimezoneCnfigFieldsToEventsAndCompanyTables < ActiveRecord::Migration
  def change
    add_column :events, :timezone, :string
    add_column :companies, :timezone_support, :boolean
  end
end
