class CreatePermissionsTable < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
      t.references :role
      t.string :action
      t.string :subject_class
      t.string :subject_id
    end
  end
end
