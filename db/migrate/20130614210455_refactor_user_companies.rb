class RefactorUserCompanies < ActiveRecord::Migration
  def change
    add_column :tasks, :company_user_id, :integer

    Task.includes(:event).where('user_id is not null').each do |task|
      task.company_user_id = CompanyUser.where(user_id: task.user_id, company_id: task.event.company_id).find(:first).id
    end
    remove_column :tasks, :user_id
    add_index :tasks, :company_user_id

    execute "INSERT INTO memberships (company_user_id, memberable_id, memberable_type, created_at, updated_at) (select company_users.id, events_users.event_id, 'Event', company_users.created_at, company_users.updated_at from events_users inner join company_users ON company_users.user_id=events_users.user_id inner join events on events.company_id=company_users.company_id and events.id=events_users.event_id)"
    execute "INSERT INTO memberships (company_user_id, memberable_id, memberable_type, created_at, updated_at) (select company_users.id, campaigns_users.campaign_id, 'Campaign', company_users.created_at, company_users.updated_at from campaigns_users  inner join company_users ON company_users.user_id = campaigns_users.user_id inner join campaigns on campaigns.company_id = company_users.company_id and campaigns.id=campaigns_users.campaign_id)"
    execute "INSERT INTO memberships (company_user_id, memberable_id, memberable_type, created_at, updated_at) (select company_users.id, teams_users.team_id, 'Team', company_users.created_at, company_users.updated_at from teams_users  inner join company_users ON company_users.user_id = teams_users.user_id inner join teams on teams.company_id = company_users.company_id and teams.id=teams_users.team_id)"

    drop_table :events_users
    drop_table :teams_users
    drop_table :campaigns_users
  end
end
