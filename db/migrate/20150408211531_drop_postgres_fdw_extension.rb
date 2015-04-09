class DropPostgresFdwExtension < ActiveRecord::Migration
  def change
    execute 'DROP EXTENSION IF EXISTS postgres_fdw CASCADE;'
  end
end
