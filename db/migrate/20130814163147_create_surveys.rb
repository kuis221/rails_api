class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.references :event
      t.integer :created_by_id
      t.integer :updated_by_id
      t.boolean :active, default: true

      t.timestamps
    end
    add_index :surveys, :event_id


    create_table :surveys_answers do |t|
      t.references :survey
      t.references :kpi
      t.integer :question_id
      t.references :brand
      t.text :answer

      t.timestamps
    end
  end
end
