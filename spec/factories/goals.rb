# == Schema Information
#
# Table name: goals
#
#  id               :integer          not null, primary key
#  kpi_id           :integer
#  kpis_segment_id  :integer
#  value            :decimal(, )
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  goalable_id      :integer
#  goalable_type    :string(255)
#  parent_id        :integer
#  parent_type      :string(255)
#  title            :string(255)
#  start_date       :date
#  due_date         :date
#  activity_type_id :integer
#

FactoryGirl.define do
  factory :goal do
    kpi_id nil
    kpis_segment_id nil
    value 0
    goalable_type nil
    goalable_id nil
    title nil
    start_date nil
    due_date nil
    activity_type_id nil
  end
end
