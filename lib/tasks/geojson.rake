namespace :geojson do
  desc 'Parse and load the neighborhoods from the geojson files into the database'
  task load_neighborhoods: :environment do
    ActiveRecord::Base.connection.execute(IO.read("db/neighborhoods.sql"))
  end
end
