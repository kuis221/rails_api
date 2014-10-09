class EnableTablefuncExtension < ActiveRecord::Migration
  def up
    execute 'CREATE EXTENSION IF NOT EXISTS tablefunc'
  end

  def down
    execute 'DROP EXTENSION IF EXISTS tablefunc'
  end
end
