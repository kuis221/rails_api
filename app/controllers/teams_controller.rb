class TeamsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['NAME', 'DESCRIPTION', 'MEMBERS', 'ACTIVE STATE']
      each_collection_item do |team|
        csv << [team.name, team.description, number_with_delimiter(team.users.active.count, precision: 1), team.status]
      end
    end
  end

  private

  def permitted_params
    params.permit(team: [:name, :description])[:team]
  end
end
