class Results::SurveysController < FilteredController
  defaults resource_class: ::Event
  respond_to :xls, only: :index

  helper_method :expenses_total, :return_path

  private

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['DESCRIPTION', 'CAMPAIGN NAME', 'VENUE NAME', 'ADDRESS', 'EVENT START DATE', 'EVENT END DATE', 'SURVEY CREATED DATE']
      each_collection_item do |event|
        event.surveys.each do |survey|
          survey = Csv::SurveyPresenter.new(survey, view_context)
          desc = []
          desc.push "#{survey.age} year old" if survey.age
          desc.push survey.ethnicity
          desc.push survey.gender
          csv << [desc.join(','), event.campaign_name, event.place_name, survey.place_address(event),
                  survey.event_start_date, survey.event_end_date, survey.created_date]
        end
      end
    end
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:with_surveys_only] = true unless p.key?(:user) && !p[:user].empty?
      p[:search_permission] = :index_results
      p[:search_permission_class] = Survey
    end)
  end

  def authorize_actions
    authorize! :index_results, Survey
  end

  def return_path
    results_reports_path
  end

  def permitted_search_params
    Event.searchable_params
  end
end
