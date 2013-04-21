object false

node :sEcho do
  params[:sEcho]
end

node :iTotalRecords do
  @total_objects
end

node :iTotalDisplayRecords do
  @total_objects
end

node :aaData do
  @resource_collection.map{|u| [u.first_name, u.last_name, u.email]}
end

