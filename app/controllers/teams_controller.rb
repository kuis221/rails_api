class TeamsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets(
      teams: [Team],
      users: [CompanyUser],
      campaigns: [Campaign],
      active_state: [])

    render json: buckets.flatten
  end

  private

  def permitted_params
    params.permit(team: [:name, :description])[:team]
  end

  def facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      facet_params = HashWithIndifferentAccess.new(search_params.select { |k, _v| %w(q company_id).include?(k) })
      facet_search = resource_class.do_search(facet_params, true)

      f.push build_campaign_bucket
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end
end
