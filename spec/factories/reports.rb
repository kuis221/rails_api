# == Schema Information
#
# Table name: reports
#
#  id            :integer          not null, primary key
#  company_id    :integer
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  created_by_id :integer
#  updated_by_id :integer
#  rows          :text
#  columns       :text
#  values        :text
#  filters       :text
#  sharing       :string(255)      default("owner")
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :report do
    company_id 1
    sequence(:name) {|n| "Report #{n}" }
    description "Report description"
    created_by_id 1
    updated_by_id 1
    active true
    rows nil
    columns nil
    values nil
    filters nil
  end
end
