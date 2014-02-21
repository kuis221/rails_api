# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :form_field do
    fieldable nil
    sequence(:name) {|n| "Form Field #{n}" }
    type nil
    settings nil
    ordering 1
    required false
  end

  factory :form_field_brand, :class => FormField::Brand do |f|
    sequence(:name) {|n| "Form Field Brand #{n}" }
    type "FormField::Brand"
    ordering 1
  end

  factory :form_field_marque, :class => FormField::Marque do |f|
    sequence(:name) {|n| "Form Field Marque #{n}" }
    type "FormField::Marque"
    ordering 1
  end
end
