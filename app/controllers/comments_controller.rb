class CommentsController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :edit, :update, :destroy]

  actions :index, :new, :create, :edit, :update, :destroy

  belongs_to :task, :event, :polymorphic => true

  after_filter :mark_comments_as_readed, only: :index


  private
    def mark_comments_as_readed
      collection.each{|c| c.mark_as_read! for: current_user }
    end
end
