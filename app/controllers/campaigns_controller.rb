class CampaignsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  load_and_authorize_resource

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'campaigns.name', :value => Proc.new{|campaign| @controller.view_context.link_to(campaign.name, @controller.view_context.campaign_path(campaign))}, :searchable => true},
      {:attr => :first_event, :value => ""},
      {:attr => :last_event, :value => ""},
      {:attr => :aasm_state, :column_name => 'campaigns.aasm_state', :value => Proc.new{|campaign| campaign.aasm_state.capitalize}}
    ]
    @editable  = true
    @deactivable = true
  end

  def deactivate
    if resource.active?
      resource.deactivate!
    else
      resource.activate!
    end
  end

end
