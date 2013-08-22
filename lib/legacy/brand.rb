# == Schema Information
#
# Table name: brands
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  color      :string(8)
#  active     :boolean          default(TRUE)
#  creator_id :integer
#  updater_id :integer
#  created_at :datetime
#  updated_at :datetime
#


class Legacy::Brand  < Legacy::Record
  has_many    :programs
end