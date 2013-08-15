# == Schema Information
#
# Table name: surveys
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe Survey do
  pending "add some examples to (or delete) #{__FILE__}"
end
