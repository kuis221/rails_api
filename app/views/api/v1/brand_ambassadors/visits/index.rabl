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
  attributes :id, :visit_type, :visit_type_name, :start_date, :end_date,
             :area_id, :campaign_id, :city, :description, :status
  child(:company_user => :user) do
    attributes :id, :full_name
  end

  node :campaign do |visit|
    {id: visit.campaign_id, name: visit.campaign_name}
  end

  node :area do |visit|
    {id: visit.area_id, name: visit.area_name}
  end
end

if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end