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
#  scalar_value    :decimal(10, 2)   default(0.0)
#  resultable_id   :integer
#  resultable_type :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :form_field_result do
    resultable nil
    form_field nil
    value nil
  end
end
