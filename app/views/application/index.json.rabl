object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

node :pages do
  total_pages
end

node :items do
  collection_to_json
end

unless params[:facets] != 'true'  or facets.nil?
  node :facets do
    facets
  end
end