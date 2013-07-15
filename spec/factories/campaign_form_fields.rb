# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign_form_field, :class => 'CampaignFormFields' do
    campaign nil
    kpi nil
    ordering 1
    name "MyString"
    type ""
    options "MyText"
    section_id 1
  end
end
