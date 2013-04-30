class CreateCampaigns < ActiveRecord::Migration
  def change
    create_table :campaigns do |t|
      t.string :name
      t.text :description
      t.string :aasm_state
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
  end
end
