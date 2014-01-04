object false

node :page do
  params[:page] || 1
end

node :total do
  collection_count
end

child @tasks => 'results' do
  attributes :id, :title, :due_at, :completed, :active

  attributes :statuses => :status

  child(:company_user => :user) do
    attributes :id, :full_name
  end
end

if params[:page].nil? || params[:page].to_i == 1
  node :facets do
    facets
  end
end