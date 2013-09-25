class CreateListExports < ActiveRecord::Migration
  def change
    create_table :list_exports do |t|
      t.string :list_class
      t.string :params
      t.string :export_format
      t.string :aasm_state
      t.attachment :file
      t.references :user

      t.timestamps
    end
    add_index :list_exports, :user_id
  end
end
