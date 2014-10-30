module Api
  module V1
    module BrandAmbassadors
      class VisitsController < Api::V1::FilteredController
        defaults resource_class: ::BrandAmbassadors::Visit

        load_and_authorize_resource only: [:show, :edit, :update, :destroy],
                                    class: ::BrandAmbassadors::Visit

        authorize_resource only: [:create, :index],
                           class: ::BrandAmbassadors::Visit

        resource_description do
          short 'Visits'
          formats %w(json xml)
          error 401, 'Unauthorized access'
          error 404, 'The requested resource was not found'
          error 406, 'The server cannot return data in the requested format'
          error 422, 'Unprocessable Entity: The change could not be processed because of errors on the data'
          error 500, 'Server crashed for some reason. Possible because of missing required params or wrong parameters'
          description <<-EOS

          EOS
        end

        api :GET, '/api/v1/brand_ambassadors/visits', 'Search for a list of visits'
        param :start_date, String, desc: 'A date to filter the visit list. When provided a start_date without an +end_date+, the result will only include visits that happen on this day. The date should be in the format MM/DD/YYYY.'
        param :end_date, String, desc: 'A date to filter the visit list. This should be provided together with the +start_date+ param and when provided will filter the list with those visits that are between that range. The date should be in the format MM/DD/YYYY.'
        param :user, Array, desc: 'A list of Brand Ambassador ids to filter the results'
        param :campaign, Array, desc: 'A list of Campaign ids to filter the results'
        param :area, Array, desc: 'A list of Area ids to filter the results'
        param :city, Array, desc: 'A list of City ids to filter the results'
        param :page, :number, desc: 'The number of the page, Default: 1'
        description <<-EOS
          Returns a list of visits filtered by the given params.

          The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

          The dates are returned on the user's timezone.

          *Facets*

          Faceting is a feature of Solr that determines the number of documents that match a given search and an additional criteria.

          When <page> is "1", the result will include a list of facets scoped on the following search params:

          - start_date
          - end_date

          *Facets Results*

          The API returns the facets on the following format:

            [
              {
                label: String,            # Any of: Campaigns, Brands, Location, People, Active State, Event Status
                items: [                  # List of items for the facet sorted by relevance
                  {
                    "label": String,      # The name of the item
                    "id": String,         # The id of the item, this should be used to filter the list by this items
                    "name": String,       # The param name to be use for filtering the list (campaign, user, team, place, area, status, event_status)
                    "count": Number,      # The number of results for this item
                    "selected": Boolean   # True if the list is being filtered by this item
                  },
                  ....
                ],
                top_items: [              # Some facets will return this as a list of items that have the greater number of results
                  <other list of items>
                ]
              }
            ]

          Each visit in the result set has the following attributes:
          * *id*: the visits's ID
          * *visit_type_name*: the visit's type name
          * *start_date*: the visit's start date
          * *end_date*: the visit's end date
          * *campaign_name*: the campaign to which the visit belongs
          * *area_name*: the area to which the visit belongs
          * *city*: the city for the visit
          * *description*: the visit's description
          * *status*: the visit's status
          * *user*:
            * *id*: the user id
            * *full_name*: the name of the user to which the visit belongs
        EOS
        example <<-EOS
        GET /api/v1/brand_ambassadors/visits.json
        {
          "page": 1,
          "total_pages": 8
          "total": 215,
          "facets": [
            <HERE GOES THE LIST FACETS DESCRIBED ABOVE>
          ],
          "results": [
            {
              id: 213,
              visit_type_name: "Market Visit",
              start_date: "2014-07-01",
              end_date: "2014-07-02",
              campaign_name: "Gin BA FY15",
              area_name: "Miami",
              city: "Miami",
              description: "Three Martini Lunch",
              status: "Active",
              user: {
                id: 130,
                full_name: "Nick van Tiel"
              }
            },
            {
              id: 115,
              visit_type_name: "PTO",
              start_date: "2014-07-07",
              end_date: "2014-07-11",
              campaign_name: "Absolut BA FY15",
              area_name: null,
              city: null,
              description: "",
              status: "Active",
              user: {
                id: 103,
                full_name: "Rudy Aguero"
              }
            },
            ...
          ]
        }
        EOS
        def index
          collection
        end

        api :GET, '/api/v1/brand_ambassadors/visits/:id', 'Return a visit\'s details'
        param :id, :number, required: true, desc: 'Visit ID'
        description <<-EOS
        Returns the event's details, including the actions that a user can perform on this
        event according to the user's permissions and the KPIs that are enabled for the event's campaign.

        The possible attributes returned are:
          * *id*: the visits's ID
          * *visit_type_name*: the visit's type name
          * *start_date*: the visit's start date
          * *end_date*: the visit's end date
          * *campaign_name*: the campaign to which the visit belongs
          * *area_name*: the area to which the visit belongs
          * *city*: the city for the visit
          * *description*: the visit's description
          * *status*: the visit's status
          * *user*:
            * *id*: the user id
            * *full_name*: the name of the user to which the visit belongs
        EOS

        example <<-EOS
        {
          id: 319,
          visit_type_name: "Brand Program",
          start_date: "2014-11-08",
          end_date: "2014-11-08",
          campaign_name: "Whisky Show TGL FY15",
          area_name: "Atlanta",
          city: "Atlanta",
          description: "Whiskies of the World show. ",
          status: "Active",
          user: {
            id: 88,
            full_name: "Craig Vaught"
          }
        }
        EOS
        def show
          if resource.present?
            render
          end
        end

        protected

        def facets
          @facets ||= Array.new.tap do |f|
            # select what params should we use for the facets search
            f.concat build_custom_filters_bucket

            f.push build_brand_ambassadors_bucket
            f.push build_campaign_bucket
            f.push build_areas_bucket
            f.push build_city_bucket
          end
        end

        def permitted_search_params
          params.permit(:page, :start_date, :end_date, { user: [] }, { campaign: [] }, { area: [] }, { city: [] })
        end

        def skip_default_validation
          true
        end

      end
    end
  end
end