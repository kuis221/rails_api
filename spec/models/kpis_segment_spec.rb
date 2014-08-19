# == Schema Information
#
# Table name: kpis_segments
#
#  id         :integer          not null, primary key
#  kpi_id     :integer
#  text       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ordering   :integer
#

require 'rails_helper'

describe KpisSegment, :type => :model do
  it { is_expected.to belong_to(:kpi) }
  it { is_expected.to have_many(:goals) }

  it { is_expected.to accept_nested_attributes_for(:goals) }
end
