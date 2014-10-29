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
  attributes :id, :visit_type_name, :start_date, :end_date, :campaign_name,
             :area_name, :city, :description, :status
  child(:company_user => :user) do
    attributes :id, :full_name
  end
end

if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end