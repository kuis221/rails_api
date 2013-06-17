# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  memberable_id   :integer
#  memberable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Membership < ActiveRecord::Base
  belongs_to :company_user
  belongs_to :memberable, polymorphic: true
  # attr_accessible :title, :body
end
