# == Schema Information
#
# Table name: user_groups
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#

require 'spec_helper'

describe UserGroup do
  pending "add some examples to (or delete) #{__FILE__}"
end
