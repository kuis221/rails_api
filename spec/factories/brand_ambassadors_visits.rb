# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_ambassadors_visit, :class => 'BrandAmbassadors::Visit' do
    name "MyString"
    company nil
    company_user nil
    start_date "08/26/2014"
    end_date "08/27/2014"
  end
end
