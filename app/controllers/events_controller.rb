class EventsController < InheritedResources::Base
  load_and_authorize_resource

  # This helper provide the methods to add/remove team members to the event
  include TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  respond_to_datatables do
    columns [
      {:attr => :start_date, :value => Proc.new{|event| @controller.view_context.link_to(event.start_date, @controller.view_context.event_path(event)) } },
      {:attr => :start_time },
      {:attr => :place_name },
      {:attr => :campaign_name },
      {:attr => :active ,  :value => Proc.new{|user| user.active? ? 'Active' : 'Inactive' } }
    ]
    @editable  = true
    @deactivable = true
  end

  has_scope :by_period, :using => [:start_date, :end_date]

end
