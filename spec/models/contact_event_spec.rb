# == Schema Information
#
# Table name: contact_events
#
#  id               :integer          not null, primary key
#  event_id         :integer
#  contactable_id   :integer
#  contactable_type :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'spec_helper'

describe ContactEvent do
  pending "add some examples to (or delete) #{__FILE__}"
end
