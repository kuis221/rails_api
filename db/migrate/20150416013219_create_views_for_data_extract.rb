class CreateViewsForDataExtract < ActiveRecord::Migration
  def change
    create_table :views_for_data_extracts do |t|
      ActiveRecord::Base.connection.execute(IO.read("db/views.sql"))
    end
  end
end
