# == Schema Information
#
# Table name: marques
#
#  id         :integer          not null, primary key
#  brand_id   :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Marque, :type => :model do
  it { is_expected.to belong_to(:brand) }

  it { is_expected.to validate_presence_of(:name) }
end
