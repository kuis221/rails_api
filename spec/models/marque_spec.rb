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

describe Marque do
  it { should belong_to(:brand) }

  it { should validate_presence_of(:name) }
end
