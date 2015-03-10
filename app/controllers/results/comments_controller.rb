class Results::CommentsController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :return_path

  private

  def search_params
    @search_params || (super.tap do |p|
      p[:search_permission] = :index_results
      p[:search_permission_class] = Comment
      p[:with_comments_only] = true unless p.key?(:user) && !p[:user].empty?
    end)
  end

  def authorize_actions
    authorize! :index_results, Comment
  end

  def return_path
    results_reports_path
  end

  def permitted_search_params
    Event.searchable_params
  end
end
