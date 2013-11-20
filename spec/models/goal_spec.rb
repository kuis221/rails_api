# == Schema Information
#
# Table name: goals
#
#  id              :integer          not null, primary key
#  kpi_id          :integer
#  kpis_segment_id :integer
#  value           :decimal(, )
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  goalable_id     :integer
#  goalable_type   :string(255)
#  parent_id       :integer
#  parent_type     :string(255)
#  title           :string(255)
#  start_date      :date
#  due_date        :date
#

require 'spec_helper'

describe Goal do

  it { should validate_presence_of(:goalable_id) }
  it { should validate_presence_of(:goalable_type) }

  it { should validate_numericality_of(:goalable_id) }
  it { should validate_numericality_of(:kpis_segment_id) }
  it { should validate_numericality_of(:value) }

  it { should belong_to(:goalable) }
  it { should belong_to(:parent) }
  it { should belong_to(:kpi) }
  it { should belong_to(:kpis_segment) }
end
