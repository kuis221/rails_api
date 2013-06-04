object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

node :items do
  collection_to_json
end

if @facets
  node :facets do
    @facets
  end
end