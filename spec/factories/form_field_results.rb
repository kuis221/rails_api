# == Schema Information
#
# Table name: form_field_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  value           :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  hash_value      :hstore
#  scalar_value    :decimal(15, 2)   default("0")
#  resultable_id   :integer
#  resultable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :form_field_result do
    resultable_id nil
    form_field_id nil
    value nil
  end
end
