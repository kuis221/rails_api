# == Schema Information
#
# Table name: addresses
#
#  id                   :integer          not null, primary key
#  addressable_id       :integer
#  addressable_type     :string(255)
#  street_address       :string(255)
#  supplemental_address :string(255)
#  city                 :string(255)
#  state                :string(255)
#  postal_code          :integer
#  active               :boolean          default(TRUE)
#  creator_id           :integer
#  updater_id           :integer
#  created_at           :datetime
#  updated_at           :datetime
#

class Legacy::Address < Legacy::Record
  belongs_to  :addressable, :polymorphic => true


  def single_line
    [street_address, supplemental_address, city, state, postal_code].compact.join(' ')
  end
end
