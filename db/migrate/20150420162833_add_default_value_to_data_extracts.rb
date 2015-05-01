class AddDefaultValueToDataExtracts < ActiveRecord::Migration
  def up
    change_column :data_extracts, :active, :boolean, default: true
    DataExtract.find_each do |p|
      p.update_column(:active, true) if p.active.nil?
    end
  end

  def down
  end
end