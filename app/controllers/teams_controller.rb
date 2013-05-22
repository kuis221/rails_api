class TeamsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  include DeactivableHelper

  load_and_authorize_resource

  has_scope :with_text

  def users
    @users = resource.users.active
  end

  private
    def collection_to_json
      @teams.map{|team| {
        :id => team.id,
        :name => team.name,
        :description => team.description,
        :users_count => team.users.active.count,
        :status => team.active? ? 'Active' : 'Inactive',
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
        'active' => { :order => 'users.state' }
      }
    end

end
