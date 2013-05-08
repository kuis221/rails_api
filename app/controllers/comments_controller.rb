class CommentsController < InheritedResources::Base
  respond_to :js, only: [:index, :create, :update]

  belongs_to :task
end
