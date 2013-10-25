class Api::V1::EventsController < Api::V1::FilteredController

  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end


  api :GET, '/api/v1/events'
  param :campaign, Array, :desc => "A list of campaign ids to filter the results"
  param :status, ['Active', 'Inactive'], :desc => "A list of event status to filter the results"
  param :event_status, ['Unsent', 'Submitted', 'Approved', 'Rejected', 'Late', 'Due'], :desc => "A list of event recap status to filter the results"
  param :page, :number, :desc => "The number of the page, Default: 1"
  description <<-EOS
    Returns a list of events filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    *Facets*

    When <page> is "1", the result will include a list of facets scoped on the following search params

    - start_date
    - end_date
  EOS
  def index
    collection
  end

  protected

    def permitted_search_params
      params.permit({campaign: []}, {status: []}, {event_status: []})
    end

    def facet_params
      params.permit(:start_date, :end_date)
    end

end