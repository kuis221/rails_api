FormField unless defined? FormField
require 'form_field/time'
require 'form_field/date'

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
#  kpi_id         :integer
#  multiple       :boolean
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :form_field do
    fieldable nil
    sequence(:name) { |n| "Form Field #{n}" }
    type nil
    settings nil
    sequence(:ordering) { |n| n }
    required false
    multiple false
  end

  factory :form_field_text_area, class: FormField::TextArea do
    sequence(:name) { |n| "Form Field TextArea #{n}" }
    type 'FormField::TextArea'
    ordering 1
  end

  factory :form_field_date, class: FormField::Date do
    sequence(:name) { |n| "Form Field Date #{n}" }
    type 'FormField::Date'
    ordering 1
  end

  factory :form_field_number, class: FormField::Number do
    sequence(:name) { |n| "Form Field Number #{n}" }
    type 'FormField::Number'
    ordering 1
  end

  factory :form_field_section, class: FormField::Section do
    sequence(:name) { |n| "Section #{n}" }
    type 'FormField::Section'
    ordering 1
  end

  factory :form_field_text, class: FormField::Text do
    sequence(:name) { |n| "Form Field Text #{n}" }
    type 'FormField::Text'
    ordering 1
  end

  factory :form_field_radio, class: FormField::Radio do
    sequence(:name) { |n| "Form Field Radio #{n}" }
    type 'FormField::Radio'
    ordering 1
  end

  factory :form_field_checkbox, class: FormField::Checkbox do
    sequence(:name) { |n| "Form Field Checkbox #{n}" }
    type 'FormField::Checkbox'
    ordering 1
  end

  factory :form_field_currency, class: FormField::Currency do
    sequence(:name) { |n| "Form Field Currency #{n}" }
    type 'FormField::Currency'
    ordering 1
  end

  factory :form_field_percentage, class: FormField::Percentage do
    sequence(:name) { |n| "Form Field Percentage #{n}" }
    type 'FormField::Percentage'
    ordering 1
  end

  factory :form_field_calculation, class: FormField::Calculation do
    sequence(:name) { |n| "Form Field Calculation #{n}" }
    type 'FormField::Calculation'
    operation '+'
    calculation_label 'TOTAL'
    ordering 1
  end

  factory :form_field_likert_scale, class: FormField::LikertScale do
    sequence(:name) { |n| "Form Field Likert Scale #{n}" }
    type 'FormField::LikertScale'
    ordering 1
  end

  factory :form_field_dropdown, class: FormField::Dropdown do
    sequence(:name) { |n| "Form Field Dropdown #{n}" }
    type 'FormField::Dropdown'
    ordering 1
  end

  factory :form_field_brand, class: FormField::Brand do
    sequence(:name) { |n| "Form Field Brand #{n}" }
    type 'FormField::Brand'
    ordering 1
  end

  factory :form_field_marque, class: FormField::Marque do
    sequence(:name) { |n| "Form Field Marque #{n}" }
    type 'FormField::Marque'
    ordering 1
  end

  factory :form_field_attachment, class: FormField::Attachment do
    sequence(:name) { |n| "Attachment #{n}" }
    type 'FormField::Attachment'
    ordering 1
  end

  factory :form_field_place, class: FormField::Place do
    sequence(:name) { |n| "Place #{n}" }
    type 'FormField::Place'
    ordering 1
  end

  factory :form_field_photo, class: FormField::Photo do
    sequence(:name) { |n| "Photo #{n}" }
    type 'FormField::Photo'
    ordering 1
  end

  factory :form_field_time, class: FormField::Time do
    sequence(:name) { |n| "Form Field Time #{n}" }
    type 'FormField::Time'
    ordering 1
  end
end
