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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :kpis_segment do
    kpi_id nil
    sequence(:text) { |n| "Kpi Segment #{n}" }
  end
end
