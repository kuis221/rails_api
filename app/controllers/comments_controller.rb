class CommentsController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :edit, :update, :destroy]

  actions :index, :new, :create, :edit, :update, :destroy

  belongs_to :task, :event, :polymorphic => true
end
