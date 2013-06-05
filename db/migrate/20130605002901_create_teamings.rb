class CreateTeamings < ActiveRecord::Migration
  def change
    create_table :teamings do |t|
      t.references :team
      t.integer :teamable_id
      t.string :teamable_type
    end
    add_index :teamings, :team_id
    add_index :teamings, [:teamable_id, :teamable_type]
    add_index :teamings, [:team_id, :teamable_id, :teamable_type], unique: true
  end
end
