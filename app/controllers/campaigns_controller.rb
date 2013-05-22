class CampaignsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  include DeactivableHelper

  load_and_authorize_resource

  has_scope :with_text

  protected
    def collection_to_json
      collection.map{|campaign| {
        :id => campaign.id,
        :name => campaign.name,
        :description => campaign.description,
        :first_event => campaign.first_event.try(:start_date),
        :last_event => campaign.last_event.try(:start_date),
        :status => campaign.active? ? 'Active' : 'Inactive',
        :links => {
            edit: edit_campaign_path(campaign),
            show: campaign_path(campaign),
            activate: activate_campaign_path(campaign),
            deactivate: deactivate_campaign_path(campaign)
        }
      }}
    end
    def sort_options
      {
        'name' => { :order => 'campaigns.name' },
        'description' => { :order => 'campaigns.description' },
        'first_event' => { :order => 'campaigns.city' },
        'last_event' => { :order => 'campaigns.state' },
        'status' => { :order => 'campaigns.state' }
      }
    end
end
