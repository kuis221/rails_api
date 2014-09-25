# == Schema Information
#
# Table name: brand_ambassadors_visits
#
#  id              :integer          not null, primary key
#  company_id      :integer
#  company_user_id :integer
#  start_date      :date
#  end_date        :date
#  active          :boolean          default(TRUE)
#  created_at      :datetime
#  updated_at      :datetime
#  description     :text
#  visit_type      :string(255)
#  brand_id        :integer
#  area_id         :integer
#  city            :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_ambassadors_visit, class: 'BrandAmbassadors::Visit' do
    description 'Visit description'
    company nil
    association :company_user
    start_date '08/26/2014'
    end_date '08/27/2014'
    active true
    visit_type 'brand_program'
    campaign { create(:campaign, company: company) }
    area_id 1
    city 'Test City'
  end
end
