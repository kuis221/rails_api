class AddSettingsToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :settings, :hstore
  end
end
