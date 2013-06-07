class EventsController < FilteredController
  load_and_authorize_resource except: [:index, :autocomplete]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  # Search the events
  before_filter :search_events, only: :index

  helper_method :filters

  def autocomplete
    buckets = []

    # Search compaigns
    search = Sunspot.search(Campaign) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Campaigns", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })


    # Search brands
    search = Sunspot.search(Brand) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
    end
    buckets.push(label: "Brands", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search places
    search = Sunspot.search(Place) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
    end
    buckets.push(label: "Places", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    # Search users
    search = Sunspot.search(User, Team) do
      keywords(params[:q]) do
        fields(:name_txt)
      end
      any_of do
        with :active_company_ids, current_company.id # For the users
        with :company_id, current_company.id  # For the teams
      end
    end
    buckets.push(label: "People", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })


    render :json => buckets.flatten
  end

  protected
    def search_events
      # Search events
      search = Sunspot.search(Event) do
        with(:user_ids, params[:user]) if params.has_key?(:user) and params[:user].present?
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team].present?
        with(:place_id, params[:place]) if params.has_key?(:place) and params[:place].present?
        with(:campaign_id, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?
        with(:brand_ids, params[:brand]) if params.has_key?(:brand) and params[:brand].present?
        if params[:start_date].present? and params[:end_date].present?
          with :start_at, Timeliness.parse(params[:start_date])..Timeliness.parse(params[:end_date])
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date])
          with :start_at, d.beginning_of_day..d.end_of_day
        end
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'campaign', 'place'
            with "#{attribute}_id", value
          else
            with "#{attribute}_ids", value
          end
        end
        with(:company_id, current_company.id)

        order_by(params[:sorting] || :start_at , params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1)
      end
      @events = search.results
      @collection_count = search.total


      # Get the facets without all the filters
      if params[:facets] == 'true'
        search = Sunspot.search(Event) do
          if params[:start_date].present? and params[:end_date].present?
            d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
            d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
            with :start_at, d1..d2
          elsif params[:start_date].present?
            d = Timeliness.parse(params[:start_date], zone: :current)
            with :start_at, d.beginning_of_day..d.end_of_day
          end
          if params.has_key?(:q) and params[:q].present?
            (attribute, value) = params[:q].split(',')
            case attribute
            when 'campaign', 'place'
              with "#{attribute}_id", value
            else
              with "#{attribute}_ids", value
            end
          end
          with(:company_id, current_company.id)
          facet :campaign
          facet :place
          facet :users
          facet :teams
          facet :brands
          facet :status

          order_by(params[:sorting] || :start_at , params[:sorting_dir] || :desc)
          paginate :page => (params[:page] || 1)
        end
        @facets = []
        @facets.push(label: "Places", items: search.facet(:place).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :place, count: x.count} })
        @facets.push(label: "Campaigns", items: search.facet(:campaign).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :campaign, count: x.count} })
        @facets.push(label: "Brands", items: search.facet(:brands).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, name: :brand, count: x.count} })
        users = search.facet(:users).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, count: x.count, name: :user} }
        teams = search.facet(:teams).rows.map{|x| id, name = x.value.split('||'); {label: name, id: id, count: x.count, name: :team} }
        people = (users + teams).sort_by { |k| k[:count] }
        @facets.push(label: "People", items: people )
      end
    end

    def begin_of_association_chain
      current_company
    end

    def collection_to_json
      collection.map{|event| {
        :id => event.id,
        :start_date => event.start_date,
        :start_time => event.start_time,
        :end_date => event.end_date,
        :end_time => event.end_time,
        :active=> event.active,
        :start_at => event.start_at.to_s,
        :end_at => event.end_at.to_s,
        :place => {
            :name => event.place_name || '',
            :latitude => event.place_latitude || '',
            :longitude => event.place_longitude || '',
            :formatted_address => event.place_formatted_address || ''
        },
        :campaign => { :name => event.campaign_name },
        :status => event.active? ? 'Active' : 'Inactive',
        :links => {
            edit: edit_event_path(event),
            show: event_path(event),
            activate: activate_event_path(event),
            deactivate: deactivate_event_path(event)
        }
      }}
    end

    def controller_filters(c)
      c.includes([:campaign, :place])
    end
end
