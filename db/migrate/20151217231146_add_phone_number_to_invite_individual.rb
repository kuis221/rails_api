class AddPhoneNumberToInviteIndividual < ActiveRecord::Migration
  def change
    add_column :invite_individuals, :phone_number, :string
  end
end
