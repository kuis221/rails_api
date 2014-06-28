class CreateSatisfactionSurveys < ActiveRecord::Migration
  def change
    create_table :satisfaction_surveys do |t|
      t.references :company_user
      t.string :session_id
      t.string :rating
      t.text :feedback

      t.timestamps
    end
    add_index :satisfaction_surveys, :company_user_id
  end
end
