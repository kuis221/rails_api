# == Schema Information
#
# Table name: neighborhoods
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  city       :string(255)
#  state      :string(255)
#  county     :string(255)
#  country    :string(255)
#  geometry   :text
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

RSpec.describe Neighborhood, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
