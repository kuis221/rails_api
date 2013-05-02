class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.references :campaign
      t.references :company
      t.datetime :start_at
      t.datetime :end_at
      t.string :aasm_state
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :events, :campaign_id
  end
end
