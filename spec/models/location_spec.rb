# == Schema Information
#
# Table name: locations
#
#  id   :integer          not null, primary key
#  path :string(500)
#

require 'rails_helper'

describe Location, type: :model do
  it { is_expected.to have_and_belong_to_many(:places) }
end
