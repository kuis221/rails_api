class Api::V1::EventsController < Api::V1::FilteredController

  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end


  api :GET, '/api/v1/events'
  param :campaign, Array
  def index
    collection
  end


  protected

    def permitted_search_params
      params.permit({campaign: []})
    end

end