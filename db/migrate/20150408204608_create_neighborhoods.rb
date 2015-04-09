class CreateNeighborhoods < ActiveRecord::Migration
  def up
    drop_table :neighborhoods if ActiveRecord::Base.connection.table_exists? 'neighborhoods'

    create_table :neighborhoods, primary_key: :gid do |t|
      t.string :state, limit: 2
      t.string :county, limit: 43
      t.string :city, limit: 64
      t.string :name, limit: (64)
      t.decimal :regionid
      t.multi_polygon :geog
    end

    add_index :neighborhoods, :geog, using: :gist

    ActiveRecord::Base.connection.execute(IO.read("db/neighborhoods.sql"))
  end

  def down
    drop_table :neighborhoods
  end
end
