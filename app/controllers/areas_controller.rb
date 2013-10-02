class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  belongs_to :place, optional: true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_places, :add_places, :add_to_campaign]

  def autocomplete
    buckets = autocomplete_buckets({
      areas: [Area]
    })
    render :json => buckets.flatten
  end

  def create
    create! do |success, failure|
      success.js do
        parent.areas << resource if parent? and parent
        render :create
      end
    end
  end

  def add_to_campaign
    campaign = current_company.campaigns.find(params[:campaign_id])
    if can?(:edit, campaign) && !campaign.area_ids.include?(resource.id)
      campaign.areas << resource
    end
  end

  def remove_from_campaign
    campaign = current_company.campaigns.find(params[:campaign_id])
    if can?(:edit, campaign) && campaign.area_ids.include?(resource.id)
      campaign.areas.delete resource
    end
  end

  private
    def permitted_params
      params.permit(area: [:name, :description])[:area]
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end
end