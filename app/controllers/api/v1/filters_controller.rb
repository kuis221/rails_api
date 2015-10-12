class Api::V1::FiltersController < Api::V1::ApiController
  skip_authorization_check only: [:show]
  skip_load_and_authorize_resource only: [:show]

  api :GET, '/api/v1/filters/:id', 'Get a the available filters for a given section'
  param :id, %w(events venues visits teams_tasks user_tasks), required: true, desc: 'The section to obtain the filters for'
  description <<-EOS
    The API returns the filters on the following format:
      {
        filters: [
          {
            label: String,            # Any of: Campaigns, Brands, Location, People, Active State, Event Status
            items: [                  # List of items for the facet sorted by relevance
              {
                "label": String,      # The name of the item
                "id": String,         # The id of the item, this should be used to filter the list by this items
                "name": String,       # The param name to be use for filtering the list (campaign, user,
                                      # team, place, area, status, event_status)
                "count": Number,      # The number of results for this item
                "selected": Boolean   # True if the list is being filtered by this item. NOTE: this is
                                      # not longer valid, it's kept only for backward
                                      # compatibility and will be removed in a later version
              },
              ....
            ],
            top_items: [              # Some facets will return this as a list of items that have the greater number of results
              <other list of items>
            ]
          }
        ]
      }

  EOS
  def show
    render json: { filters: collection_filters.filters }
  end

  protected

  def collection_filters
    @collection_filters ||= CollectionFilter.new(params[:id], current_company_user, params)
  end
end
