object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

child @photos => 'results' do
  extends "api/v1/photos/photo"
end
