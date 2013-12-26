# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :kpis_segment do
    kpi_id nil
    sequence(:text) { |n| "Kpi Segment #{n}" }
  end
end
