class AddModulesToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :modules, :text
    Campaign.all.each do |c|
      modules = c.read_attribute('enabled_modules')
      c.modules = Hash[modules.map { |m| [m, {}] }]
      c.save
    end
    remove_column :campaigns, :enabled_modules
  end
end
