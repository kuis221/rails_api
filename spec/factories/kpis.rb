# == Schema Information
#
# Table name: kpis
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  description       :text
#  kpi_type          :string(255)
#  capture_mechanism :string(255)
#  company_id        :integer
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  module            :string(255)      default("custom"), not null
#  ordering          :integer
#

FactoryGirl.define do
  factory :kpi do
    sequence(:name) { |n| "Kpi #{n}" }
    description 'MyText'
    kpi_type 'number'
    capture_mechanism 'integer'
    'module' 'custom'
    company_id 1
  end
end
