class CreateViews < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute(IO.read("db/functions.sql"))
    ActiveRecord::Base.connection.execute(IO.read("db/views.sql"))
  end
end
