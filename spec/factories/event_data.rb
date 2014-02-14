# == Schema Information
#
# Table name: event_data
#
#  id                        :integer          not null, primary key
#  event_id                  :integer
#  impressions               :integer          default(0)
#  interactions              :integer          default(0)
#  samples                   :integer          default(0)
#  gender_female             :decimal(5, 2)    default(0.0)
#  gender_male               :decimal(5, 2)    default(0.0)
#  ethnicity_asian           :decimal(5, 2)    default(0.0)
#  ethnicity_black           :decimal(5, 2)    default(0.0)
#  ethnicity_hispanic        :decimal(5, 2)    default(0.0)
#  ethnicity_native_american :decimal(5, 2)    default(0.0)
#  ethnicity_white           :decimal(5, 2)    default(0.0)
#  spent                     :decimal(10, 2)   default(0.0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

FactoryGirl.define do
    factory :event_data do
    event nil
    impressions   0
    interactions  0
    samples       0
    gender_female 0
    gender_male   0
    ethnicity_asian           0
    ethnicity_black           0
    ethnicity_hispanic        0
    ethnicity_native_american 0
    ethnicity_white           0
    spent                     0
  end
end
