class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.references :company_user
      t.references :memberable, polymorphic: true

      t.timestamps
    end
    add_index :memberships, :company_user_id
    add_index :memberships, [:memberable_id, :memberable_type]
  end
end
