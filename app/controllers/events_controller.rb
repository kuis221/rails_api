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

    def end_of_association_chain
      current_page = params[:page] || 1
      @total_objects = super.count

      super.includes([:campaign, :place]).scoped(sorting_options).page(current_page)
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
