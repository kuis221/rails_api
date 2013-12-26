class Api::V1::VenuesController < Api::V1::FilteredController

  resource_description do
    short 'Venues'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the "
    description <<-EOS

    EOS
  end


  api :GET, '/api/v1/venues/search', "Search for a list of venues matching a term"
  param :term, String, :desc => "The search term"

  description <<-EOS
    Returns a list of venues matching the search +term+ ordered by relevance limited to 10 results.

    The response consist on a list or the following attributes:
    * *id*: the place id or reference that have to be sent when creating/updating events, this can be either an number or a large string.
    * *value*: the description of the venue, including the name and address
    * *label*: this exactly the same as +value+
  EOS

  example <<-EOS
  [{
      "value":"Bar None, 1980 Union Street, San Francisco, CA, United States",
      "label":"Bar None, 1980 Union Street, San Francisco, CA, United States",
      "id":90
    },
   {
      "value":"Bar None, 98 3rd Avenue, New York, NY, United States",
      "label":"Bar None, 98 3rd Avenue, New York, NY, United States",
      "id":"CnRpAAAAT5JxPtj5WPge6_MkN0q55Ati4lj_HSCXLwx9ZS-zh6B-YF9fLsizZtjXAiPA-loJKiNNh0JxNUIdMGJUwk5lqR1jxhzGmPWBp01bCOGfRdFS3KKybejTmvlFI7EeTjV_g_9b_aAAYtl9OOYS4ght5BIQ0Z0OUWz2Zgnyx2ln6BVEvhoUaZ9DhhS2g56S4ZYfogaJjs0rb4o||07f11bfbcd5a70e34d2dceef794e6d07aa34b7ee"
    }]
  EOS
  def search
    @venues = Place.combined_search(company_id: current_company.id, q: params[:term], search_address: true)

    render json: @venues.first(10)
  end

end