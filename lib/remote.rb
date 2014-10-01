require 'remote/record'
Dir[Rails.root.to_s + '/lib/remote/**/*.rb'].each do |file|
  require file
end
