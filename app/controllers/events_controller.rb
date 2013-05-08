class EventsController < InheritedResources::Base
  load_and_authorize_resource

  # This helper provide the methods to add/remove team members to the event
  include TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  respond_to_datatables do
    columns [
      {:attr => :start_date, :value => Proc.new{|event| @controller.view_context.link_to(event.start_date, @controller.view_context.event_path(event)) }, :column_name => 'events.start_at', :searchable => true},
      {:attr => :start_time, :column_name => 'events.start_at', :searchable => true},
      {:attr => :place_name },
      {:attr => :campaign_name ,:column_name => 'campaign.name'}
    ]
    @editable  = true
    @deactivable = false
  end


end
