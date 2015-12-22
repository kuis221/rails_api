class AddMissingColumnsToInviteIndividual < ActiveRecord::Migration
  def change
    add_column :invite_individuals, :age, :integer
    add_column :invite_individuals, :address_line_1, :string
    add_column :invite_individuals, :address_line_2, :string
    add_column :invite_individuals, :city, :string
    add_column :invite_individuals, :province_code, :string
    add_column :invite_individuals, :country_code, :string
  end
end
