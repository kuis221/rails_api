class AddInvitationCreatedAtToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :invitation_created_at, :datetime
    change_column :users, :invitation_token, :string, limit: 255
  end
end
