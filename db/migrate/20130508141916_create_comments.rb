class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true
      t.text :content
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :comments, [:commentable_type, :commentable_id]
  end
end
