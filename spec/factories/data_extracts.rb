# == Schema Information
#
# Table name: data_extracts
#
#  id               :integer          not null, primary key
#  type             :string(255)
#  company_id       :integer
#  active           :boolean          default("true")
#  sharing          :string(255)
#  name             :string(255)
#  description      :text
#  columns          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime
#  updated_at       :datetime
#  default_sort_by  :string(255)
#  default_sort_dir :string(255)
#  params           :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :data_extract do
    type ''
    company nil
    active false
    sharing 'MyString'
    sequence(:name) { |n| "Data Extract #{n}" }
    description 'MyText'
    columns []

    factory :data_extract_event_data, class: DataExtract::EventData do
      sequence(:name) { |n| "Event Data Extract #{n}" }
      type 'DataExtract::EventData'
    end
  end
end
