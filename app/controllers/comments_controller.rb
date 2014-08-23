class CommentsController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :edit, :update, :destroy]

  actions :index, :new, :create, :edit, :update, :destroy

  belongs_to :task, :event, :polymorphic => true

  after_filter :mark_comments_as_readed, only: :index

  authorize_resource except: [:index]

  before_action :authorize_actions, only: :index


  private
    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(comment: [:content])[:comment]
    end

    def mark_comments_as_readed
      collection.each{|c| c.mark_as_read! for: current_user }
    end

    def authorize_actions
      authorize! :comments, parent
    end


end
