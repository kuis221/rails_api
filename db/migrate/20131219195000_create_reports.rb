class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :type
      t.integer :company_user_id
      t.text   :params
      t.string :aasm_state
      t.integer :progress
      t.attachment :file

      t.timestamps
    end
  end
end
