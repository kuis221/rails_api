class DropPostgresFdwExtension < ActiveRecord::Migration
  def up
    execute 'DROP EXTENSION IF EXISTS postgres_fdw CASCADE;'
  end
  def down
    execute 'CREATE EXTENSION postgres_fdw;'
  end
end
