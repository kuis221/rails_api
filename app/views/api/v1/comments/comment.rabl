attributes :id, :content, :created_at

node do |comment|
  if comment.commentable_type == 'Task'
    child(:user => :created_by) do
      attributes :id, :full_name
    end
  end
end