class CommentsController < InheritedResources::Base
  respond_to :js, only: [:index, :create]

  actions :index, :create

  belongs_to :task, :event, :polymorphic => true
end
