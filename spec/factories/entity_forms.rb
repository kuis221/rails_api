# == Schema Information
#
# Table name: entity_forms
#
#  id         :integer          not null, primary key
#  entity     :string(255)
#  entity_id  :integer
#  company_id :integer
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :entity_form do
    entity 'MyString'
    company nil
  end
end
