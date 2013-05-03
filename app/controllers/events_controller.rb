class EventsController < InheritedResources::Base

  load_and_authorize_resource

  respond_to :js, only: [:new, :create, :edit, :update]

  respond_to_datatables do
    columns [
      {:attr => :start_date, :value => Proc.new{|event| @controller.view_context.link_to(event.start_date, @controller.view_context.event_path(event)) }, :column_name => 'events.start_at', :searchable => true},
      {:attr => :start_time, :column_name => 'events.start_at', :searchable => true},
      {:attr => :location, :value => Proc.new{|event| '' }},
      {:attr => :campaign_name ,:column_name => 'campaign.name'}
    ]
    @editable  = true
    @deactivable = false
  end
end
