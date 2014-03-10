class Results::CommentsController < FilteredController

  defaults :resource_class => ::Event
  respond_to :xls, only: :index

  private

    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:user) && !@search_params[:user].empty?
          @search_params[:with_comments_only] = true
        end
        @search_params
      end
    end

    def authorize_actions
      authorize! :index_results, Comment
    end
end