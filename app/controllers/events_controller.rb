class EventsController < FilteredController
  load_and_authorize_resource except: :index

  # This helper provide the methods to add/remove team members to the event
  include TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  # Scopes for the filter box
  has_scope :by_period, :using => [:start_date, :end_date]
  has_scope :with_text

  protected

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

    def sort_options
      {
        'start_at' => { :order => 'events.start_at' },
        'start_time' => { :order => 'to_char(events.start_at, \'HH24:MI:SS\')' },
        'location' => { :order => 'places.name' },
        'campaign' => { :order => 'campaigns.name' },
        'status' => { :order => 'events.active' }
      }
    end



end
