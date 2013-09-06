class TeamsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets({
      teams: [Team],
      users: [CompanyUser],
      campaigns: [Campaign]
    })

    render :json => buckets.flatten
  end

  private
    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, count: x.count, name: :campaign}) } )
        f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end

    def delete_member_path(team)
      path = nil
      path = delete_team_campaign_path(params[:campaign], team_id: team.id) if params.has_key?(:campaign) && params[:campaign].present?
      path
    end
end