class AddReportsExtensionAndView < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION tablefunc;"
  end

  def down
    execute "DROP EXTENSION tablefunc;"
  end
end
