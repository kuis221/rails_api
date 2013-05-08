class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :name
      t.attachment :file
      t.references :documentable, :polymorphic => true
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :documents, [:documentable_type, :documentable_id]
  end
end
