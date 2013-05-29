class CampaignsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  include DeactivableHelper

  # This helper provide the methods to add/remove campaigns members to the event
  include TeamMembersHelper

  load_and_authorize_resource except: :index

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
        :active => campaign.active?,
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
        'status' => { :order => 'campaigns.aasm_state' }
      }
    end
end
