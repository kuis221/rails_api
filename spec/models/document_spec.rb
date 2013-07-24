# == Schema Information
#
# Table name: documents
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  event_id      :integer
#

require 'spec_helper'

describe Document do
  it { should allow_mass_assignment_of(:name) }

  it { should validate_presence_of(:name) }
end
