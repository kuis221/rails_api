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

require 'spec_helper'

describe Membership do
  pending "add some examples to (or delete) #{__FILE__}"
end
