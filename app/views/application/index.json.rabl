object false

node :total do
  collection_count
end

node :items do
  collection_to_json
end
