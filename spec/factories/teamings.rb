# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :teaming do
    team nil
    teamable nil
  end
end
