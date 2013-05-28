object false
extends "application/index"

node :unassigned do
 @collection_count_scope.where(:user_id => nil).count
end

node :completed do
  @collection_count_scope.where(:completed => true).count
end

node :assigned do
  @collection_count_scope.where('tasks.user_id is not null').count
end