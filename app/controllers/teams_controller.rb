class TeamsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to add/remove team members to the event
  extend TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  load_and_authorize_resource except: :index

  has_scope :with_text

  private
    def collection_to_json
      collection.map{|team| {
        :id => team.id,
        :name => team.name,
        :description => team.description,
        :users_count => team.users.active_in_company(current_company).count,
        :status => team.active? ? 'Active' : 'Inactive',
        :active => team.active?,
        :links => {
            edit: edit_team_path(team),
            show: team_path(team),
            activate: activate_team_path(team),
            deactivate: deactivate_team_path(team)
        }
      }}
    end
    def sort_options
      {
        'name' => { :order => 'teams.name' },
        'description' => { :order => 'teams.description' },
        'status' => { :order => 'teams.active' }
      }
    end

end
