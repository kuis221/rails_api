object false

node :sEcho do
  params[:sEcho]
end

node :iTotalRecords do
  @users.count
end

node :iTotalDisplayRecords do
  @users.count
end

node :aaData do
  @users.map{|u| [u.last_name, u.first_name, u.user_group_name, u.city, u.state_name, u.email, u.aasm_state.capitalize] }
end
