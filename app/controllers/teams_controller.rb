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
end
