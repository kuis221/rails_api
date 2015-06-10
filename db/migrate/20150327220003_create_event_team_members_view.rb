class CreateEventTeamMembersView < ActiveRecord::Migration
  def up
    execute 'CREATE VIEW event_team_members AS
                SELECT events.id as event_id, users.id user_id, company_users.id company_user_id
                FROM events
                LEFT JOIN teamings ON teamings.teamable_id=events.id AND teamable_type=\'Event\'
                LEFT JOIN teams ON teams.id=teamings.team_id
                LEFT JOIN memberships ON (memberships.memberable_id=events.id AND memberable_type=\'Event\') OR
                                         (memberships.memberable_id=teams.id AND memberable_type=\'Team\')
                LEFT JOIN company_users ON company_users.id=memberships.company_user_id
                LEFT JOIN users ON users.id=company_users.user_id'
  end

  def down
    execute 'DROP view event_team_members'
  end
end
