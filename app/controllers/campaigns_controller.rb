class CampaignsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  load_and_authorize_resource

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'campaigns.name', :searchable => true},
      {:attr => :description, :column_name => 'campaigns.description', :searchable => true},
      {:attr => :first_event, :value => Proc.new{|campaign| campaign.first_event.try(:start_date)}},
      {:attr => :last_event, :value => Proc.new{|campaign| campaign.last_event.try(:start_date)}},
      {:attr => :aasm_state, :column_name => 'campaigns.aasm_state', :value => Proc.new{|campaign| campaign.aasm_state.capitalize}}
    ]
    @editable  = true
    @deactivable = true
  end

end
