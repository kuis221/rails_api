# == Schema Information
#
# Table name: neighborhoods
#
#  gid      :integer          not null, primary key
#  state    :string(2)
#  county   :string(43)
#  city     :string(64)
#  name     :string(64)
#  regionid :decimal(, )
#  geog     :spatial          multipolygon, 4326
#

require 'rails_helper'

RSpec.describe Neighborhood, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
