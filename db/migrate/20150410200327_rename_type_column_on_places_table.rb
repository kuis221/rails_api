class RenameTypeColumnOnPlacesTable < ActiveRecord::Migration
  def up
    rename_column :places, :types, :types_old
    add_column :places, :types, :string, array: true
    Place.find_each do |p| 
      p.update_column(:types, YAML.load(p.types_old)) unless p.types_old.nil?
    end
  end

  def down
    remove_column :places, :types
    rename_column :places, :types_old, :types
  end
end
