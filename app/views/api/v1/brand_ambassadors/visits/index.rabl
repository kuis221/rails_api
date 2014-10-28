object false

node :page do
  params[:page] || 1
end

node :total_pages do
  total_pages
end

node :total do
  collection_count
end

child @visits => 'results' do

  attributes :id, :start_date, :end_date, :status
end


if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end