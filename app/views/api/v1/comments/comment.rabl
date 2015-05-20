attributes :id, :content, :created_at

node do |comment|
  child(:user => :created_by) do
    attributes :id, :full_name
  end
end