class Results::CommentsController < FilteredController
  defaults resource_class: ::Event
  respond_to :csv, only: :index

  helper_method :return_path

  private

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'COUNTRY', 'EVENT START DATE', 'EVENT END DATE', 'COMMENT']
      each_collection_item do |event|
        event.comments.each do |comment|
          csv << [event.campaign_name, event.place_name, event.place_address, event.place_country, event.start_date, event.end_date, comment.content]
        end
      end
    end
  end

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
