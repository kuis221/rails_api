class CreateInviteIndividualInvites < ActiveRecord::Migration
  def change
    create_table :invite_individual_invites do |t|
      t.references :invite_individual, index: true, foreign_key: true
      t.references :invite, index: true, foreign_key: true
    end
  end
end
