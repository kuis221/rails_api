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
  it { should validate_numericality_of(:kpi_id) }
  it { should validate_numericality_of(:kpis_segment_id) }
  it { should validate_numericality_of(:value) }

  it { should belong_to(:goalable) }
  it { should belong_to(:parent) }
  it { should belong_to(:kpi) }
  it { should belong_to(:kpis_segment) }


  describe "set_kpi_id" do
    it "should set the kpi_id if nill and the kpis_segment_id is set" do
      segment = FactoryGirl.create(:kpis_segment, kpi: FactoryGirl.create(:kpi))
      goal = Goal.new(kpis_segment_id: segment.id)
      goal.valid?
      expect(goal.kpi_id).to eql segment.kpi_id
    end
  end
end
