# == Schema Information
#
# Table name: kpis_segments
#
#  id         :integer          not null, primary key
#  kpi_id     :integer
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe KpisSegment do
  it { should belong_to(:kpi) }
  it { should have_many(:goals) }
  it { should have_many(:event_results) }

  it { should allow_mass_assignment_of(:text) }
  it { should allow_mass_assignment_of(:goals_attributes) }

  it { should accept_nested_attributes_for(:goals) }
end
