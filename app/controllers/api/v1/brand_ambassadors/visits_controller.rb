module Api
  module V1
    module BrandAmbassadors
      class VisitsController < Api::V1::FilteredController
        defaults resource_class: ::BrandAmbassadors::Visit

        load_and_authorize_resource only: [:show, :edit, :update, :destroy, :events],
                                    class: ::BrandAmbassadors::Visit

        authorize_resource only: [:create, :index],
                           class: ::BrandAmbassadors::Visit

        skip_authorization_check only: [:types]

        resource_description do
          name 'Brand Ambassadors Visits'
          short 'Visits'
          formats %w(json xml)
          error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
          error 401, 'Unauthorized access'
          error 404, 'The requested resource was not found'
          error 406, 'The server cannot return data in the requested format'
          error 422, 'Unprocessable Entity: The change could not be processed because of errors on the data'
          error 500, 'Server crashed for some reason. Possible because of missing required params or wrong parameters'
          description <<-EOS

          EOS
        end

        def_param_group :visit do
          param :visit, Hash, required: true, action_aware: true do
            param :start_date, String, required: true, desc: "Visit's start date. Should be in format MM/DD/YYYY."
            param :end_date, String, required: true, desc: "Visit's end date. Should be in format MM/DD/YYYY."
            param :company_user_id, Integer, required: true, desc: 'Company User ID'
            param :campaign_id, Integer, allow_nil: true, required: true, desc: 'Campaign ID'
            param :area_id, Integer, desc: 'Area ID'
            param :city, String, desc: 'City name'
            param :visit_type, String, required: true, desc: 'Visit Type Tag'
            param :description, String, desc: "Visit's description"
            param :active, %w(true false),
                  required: false, desc: 'Visit\'s active state. Defaults to true for new visits '\
                                         'or unchanged for existing records.'
          end
        end

        api :GET, '/api/v1/brand_ambassadors/visits', 'Search for a list of visits'
        param :start_date, %r{\A\d{2}/\d{2}/\d{4}\z},
              desc: 'A date to filter the visit list. When provided a start_date without an '\
                    '+end_date+, the result will only include visits that happen on this day. '\
                    'The date should be in the format MM/DD/YYYY.'
        param :end_date, %r{\A\d{2}/\d{2}/\d{4}\z},
              desc: 'A date to filter the visit list. '\
                    'This should be provided together with the +start_date+ param and when '\
                    'provided will filter the list with those visits that are between that range. '\
                    'The date should be in the format MM/DD/YYYY.'
        param :user, Array, desc: 'A list of Brand Ambassador ids to filter the results'
        param :campaign, Array, desc: 'A list of Campaign ids to filter the results'
        param :area, Array, desc: 'A list of Area ids to filter the results'
        param :city, Array, desc: 'A list of City ids to filter the results'
        param :page, Integer, desc: 'The number of the page, Default: 1'
        description <<-EOS
          Returns a list of visits filtered by the given params.

          The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

          The dates are returned on the user's timezone.

          *Facets*

          Faceting is a feature of Solr that determines the number of documents that match a given search and an additional criteria.

          When <page> is "1", the result will include a list of facets scoped on the following search params:

          - start_date
          - end_date

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
          * *visit_type: the visit's type name
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
        def index
          collection
        end

        api :GET, '/api/v1/brand_ambassadors/visits/:id', 'Return a visit\'s details'
        param :id, Integer, required: true, desc: 'Visit ID'
        description <<-EOS
        Returns the event's details, including the actions that a user can perform on this
        event according to the user's permissions and the KPIs that are enabled for the event's campaign.

        The possible attributes returned are:
          * *id*: the visits's ID
          * *visit_type: the visit's type name
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
          visit_type: "Brand Program",
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
          render if resource.present?
        end

        api :POST, '/api/v1/brand_ambassadors/visits', 'Create a new visit'
        param_group :visit
        description <<-EOS
        Allows to create a new visit.
        EOS
        example <<-EOS
        POST /api/v1/brand_ambassadors/visits.json
        DATA:
        {
          visit: {
            start_date: "11/09/2014",
            end_date: "11/10/2014",
            company_user_id: "345",
            campaign_id: "115",
            area_id: "21",
            city: "Decatur",
            visit_type: "Market Visit",
            description: "My description"
          }
        }

        RESPONSE:
        {
          {
            id: 361,
            visit_type: "Market Visit",
            start_date: "2014-11-09",
            end_date: "2014-11-10",
            campaign_name: "Absolut BA FY15",
            area_name: "Atlanta",
            city: "Decatur",
            description: "My description",
            status: "Active",
            user: {
              id: 345,
              full_name: "Chris Combs"
            }
          }
        }
        EOS
        def create
          create! do |success, failure|
            success.json { render :show }
            failure.json { render json: resource.errors }
          end
        end

        api :PUT, '/api/v1/brand_ambassadors/visits/:id', 'Update a visit\'s details'
        param_group :visit
        description <<-EOS
        Allows to update an existing visit.
        EOS
        example <<-EOS
        PUT /api/v1/brand_ambassadors/visits/1.json
        DATA:
        {
          visit: {
            start_date: "11/09/2014",
            end_date: "11/10/2014",
            company_user_id: "345",
            campaign_id: "115",
            area_id: "21",
            city: "Decatur",
            visit_type: "Market Visit",
            description: "My description"
          }
        }

        RESPONSE:
        {
          {
            id: 361,
            visit_type: "Market Visit",
            start_date: "2014-11-09",
            end_date: "2014-11-10",
            campaign_id: 115,
            area_id: 21,
            city: "Decatur",
            description: "My description",
            status: "Active",
            user: {
              id: 345,
              full_name: "Chris Combs"
            }
            campaign: {
              id: 115,
              full_name: "Absolut BA FY15"
            }
            area: {
              id: 21,
              full_name: "Atlanta"
            }
          }
        }
        EOS
        def update
          update! do |success, failure|
            success.json { render :show }
            success.xml  { render :show }
            failure.json { render json: resource.errors, status: :unprocessable_entity }
            failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
          end
        end

        api :GET, '/api/v1/brand_ambassadors/visits/types', 'Returns a list of valid Visit Types to be used in forms'
        example <<-EOS
        GET /api/v1/brand_ambassadors/visits/types.json

        RESPONSE:
        {
            "Brand Program",
            "PTO",
            "Market Visit",
            "Local Market Request"
        }
        EOS
        def types
          render json: current_company.brand_ambassadors_visits.order(:visit_type).pluck(:visit_type).uniq.compact.to_json
        end

        api :GET, '/api/v1/brand_ambassadors/visits/:id/events', 'Get a list of events for a visit'
        param :id, Integer, required: true, desc: "The visit's ID."
        description <<-EOS
          Returns a list of the events for a visit.

          Each event item have the following attributes:

          * *id*: the event's ID
          * *start_date*: the event's start date
          * *start_time*: the event's start time
          * *end_date*: the event's end date
          * *end_time*: the event's end time
          * *status*: the event's active state
          * *event_status*: the event's PER status
          * *campaign*:
            * *id*: the campaign id
            * *name*: the campaign name associated to the event
          * *place*:
            * *id*: the place id
            * *name*: the name of the place associated to the event
            * *formatted_address*: full address of the place
            * *country*: country code of the place
            * *state_name*: state name of the place
            * *city*: city name of the place
            * *zipcode*: zip code of the place
        EOS
        example <<-EOS
          GET /api/v1/brand_ambassadors/visits/361/events.json
          [
            {
              id: 42397,
              start_date: "11/09/2014",
              start_time: "2:45 PM",
              end_date: "11/10/2014",
              end_time: "3:45 PM",
              campaign: {
                id: 115,
                name: "Absolut BA FY15"
              },
              place: {
                id: 6754,
                name: "Atlanta",
                formatted_address: "Atlanta, GA, USA",
                country: "US",
                state_name: "Georgia",
                city: "Atlanta",
                zipcode: null
              }
            },
            {
              id: 42398,
              start_date: "11/10/2014",
              start_time: "11:00 AM",
              end_date: "11/10/2014",
              end_time: "12:00 PM",
              campaign: {
                id: 14,
                name: "Absolut BA FY14"
              },
              place: {
                id: 6401,
                name: "Fado Irish Pub",
                formatted_address: "Atlanta, GA, United States",
                country: "US",
                state_name: "Georgia",
                city: "Atlanta",
                zipcode: null
              }
            },
            ...
          ]
        EOS
        def events
          @events = Event.do_search(
            company_id: current_company.id,
            current_company_user: current_company_user,
            start_date: resource.start_date.to_s(:slashes),
            end_date: resource.end_date.to_s(:slashes),
            campaign: [resource.campaign_id],
            user: [resource.company_user_id],
            status: ['Active']
          ).results
        end

        protected

        def facets
          collection_filters ||= CollectionFilter.new('visits', current_company_user, params)
          collection_filters.filters
        end

        def permitted_params
          params.permit(visit: [:start_date, :end_date, :company_user_id,
                                :campaign_id, :area_id, :city, :visit_type,
                                :description, :active])[:visit]
        end

        def permitted_search_params
          params.permit(
            :page, :start_date, :end_date,
            user: [], campaign: [], area: [], city: [])
        end

        def skip_default_validation
          true
        end
      end
    end
  end
end
