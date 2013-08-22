class CreateDataMigrationsTable < ActiveRecord::Migration
  def change
    create_table :data_migrations do |t|
      t.references :remote, polymorphic: true
      t.references :local, polymorphic: true
      t.references :company

      t.timestamps
    end
  end
end
