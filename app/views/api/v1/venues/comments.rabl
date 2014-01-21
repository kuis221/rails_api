collection @comments

node do |comment|
  if comment.is_a?(Comment)
    node(:type) { :brandscopic }
    partial "api/v1/comments/comment", :object => comment
  else
    node(:type) { :google }
    partial "api/v1/comments/google", :object => comment
  end
end